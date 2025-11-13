# frozen_string_literal: true

require "fileutils"
require "json"
require "net/http"
require "webrick"

module Panda
  module Core
    module Testing
      module Assets
        class Verifier
          Result = Struct.new(:ok, :errors, :timings, :checks, :http_failures, keyword_init: true)

          ENGINE_CONFIG = {
            core: {
              name: "Panda Core",
              js_public_prefix: "/assets/panda/core",
              js_local_dir: File.join("app/javascript/panda/core")
            },
            cms: {
              name: "Panda CMS",
              js_public_prefix: "/assets/panda/cms",
              js_local_dir: File.join("app/javascript/panda/cms")
            }
          }.freeze

          def self.run(engine)
            new(engine).run
          end

          def initialize(engine)
            @engine = engine.to_sym
            @errors = []
            @timings = {}
            @checks = []
            @http_failures = []
          end

          attr_reader :errors, :timings, :checks, :http_failures

          def run
            t0 = now

            assets_dir, manifest, importmap = basic_file_checks
            validate_json(manifest, importmap)
            serve_and_http_check(assets_dir, importmap, manifest)

            total = now - t0
            timings[:total_verify] = total

            Result.new(
              ok: errors.empty? && http_failures.empty?,
              errors: errors,
              timings: timings,
              checks: checks,
              http_failures: http_failures
            )
          end

          private

          def config
            ENGINE_CONFIG.fetch(@engine)
          rescue KeyError
            raise "Unknown engine for asset verification: #{@engine.inspect}"
          end

          def dummy_root
            @dummy_root ||= begin
              root = Rails.root
              if root.basename.to_s == "dummy"
                root
              else
                candidate = root.join("spec/dummy")
                raise "Cannot find dummy root at #{candidate}" unless candidate.exist?
                candidate
              end
            end
          end

          def now
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end

          def record_check(name, ok)
            checks << {name: name, ok: ok}
          end

          def basic_file_checks
            t = now
            UI.banner("#{config[:name]}: Basic asset checks", status: :ok)

            assets_dir = dummy_root.join("public/assets")
            manifest_path = assets_dir.join(".manifest.json")
            importmap_path = assets_dir.join("importmap.json")

            unless Dir.exist?(assets_dir)
              msg = "public/assets missing (#{assets_dir})"
              errors << {where: "basic", message: msg}
              UI.error(msg)
              record_check("assets_dir", false)
              return [assets_dir, nil, nil]
            end
            UI.ok("public/assets exists: #{assets_dir}")
            record_check("assets_dir", true)

            unless File.exist?(manifest_path)
              msg = ".manifest.json missing (Propshaft did not compile)"
              errors << {where: "basic", message: msg}
              UI.error(msg)
              record_check("manifest_present", false)
              return [assets_dir, nil, nil]
            end
            UI.ok(".manifest.json present")
            record_check("manifest_present", true)

            unless File.exist?(importmap_path)
              msg = "importmap.json missing"
              errors << {where: "basic", message: msg}
              UI.error(msg)
              record_check("importmap_present", false)
              return [assets_dir, nil, nil]
            end
            UI.ok("importmap.json present")
            record_check("importmap_present", true)

            timings[:basic_files] = now - t
            [assets_dir, manifest_path, importmap_path]
          end

          def validate_json(manifest_path, importmap_path)
            t = now
            UI.banner("#{config[:name]}: JSON validation", status: :ok)

            manifest = nil
            importmap = nil

            if manifest_path && File.exist?(manifest_path)
              manifest = JSON.parse(File.read(manifest_path))
              UI.ok("Parsed manifest.json (#{manifest.size} entries)")
              record_check("manifest_parse", true)
            end

            if importmap_path && File.exist?(importmap_path)
              raw = File.read(importmap_path)
              importmap = JSON.parse(raw)
              import_count =
                if importmap.is_a?(Hash) && importmap["imports"].is_a?(Hash)
                  importmap["imports"].size
                else
                  0
                end
              UI.ok("Parsed importmap.json (#{import_count} imports)")
              record_check("importmap_parse", true)
            end

            timings[:parse_json] = now - t
            [manifest, importmap]
          rescue JSON::ParserError => e
            errors << {where: "json", message: e.message}
            UI.error("JSON parse error: #{e.message}")
            record_check("json_parse", false)
            timings[:parse_json] = now - t
            [nil, nil]
          end

          def serve_and_http_check(assets_dir, importmap, manifest)
            t = now
            UI.banner("#{config[:name]}: HTTP checks", status: :ok)

            return unless assets_dir && importmap && manifest

            port = 4579
            server = WEBrick::HTTPServer.new(
              Port: port,
              DocumentRoot: dummy_root.join("public").to_s,
              AccessLog: [],
              Logger: WEBrick::Log.new(File::NULL)
            )

            server_thread = Thread.new { server.start }
            sleep 0.4

            verify_importmap_assets(importmap, port)
            verify_js_controllers(port)
            verify_manifest_assets(manifest, port)

            record_check("http_checks", http_failures.empty?)

            server.shutdown
            server_thread.join

            timings[:http_checks] = now - t
          rescue => e
            errors << {where: "http_server", message: e.message}
            UI.error("HTTP verification error: #{e.message}")
          end

          def http_fetch(path, port)
            uri = URI("http://127.0.0.1:#{port}#{path}")
            res = Net::HTTP.get_response(uri)
            [res.code.to_i, res.body]
          rescue => e
            [nil, e.message]
          end

          def verify_importmap_assets(importmap, port)
            t = now
            UI.step("Validating importmap assets via HTTP")

            imports = if importmap.is_a?(Hash) && importmap["imports"].is_a?(Hash)
              importmap["imports"]
            else
              UI.warn("Importmap has no 'imports' hash; skipping HTTP checks for imports")
              {}
            end

            imports.each do |logical, path|
              next unless path.is_a?(String)

              full_path = "/assets/#{path}"
              code, body = http_fetch(full_path, port)

              if code == 200 && !body.to_s.strip.empty?
                UI.ok("#{logical} → #{full_path}")
              else
                detail = code.nil? ? body : "HTTP #{code}"
                http_failures << {
                  category: "importmap",
                  path: full_path,
                  detail: "#{logical}: #{detail}"
                }
                UI.error("Importmap asset missing/broken: #{logical} (#{full_path}) – #{detail}")
              end
            end

            timings[:http_importmap] = now - t
          end

          def verify_js_controllers(port)
            t = now
            UI.step("Validating JS controllers (engine-level)")

            local_dir = dummy_root.join(config[:js_local_dir])
            unless Dir.exist?(local_dir)
              UI.warn("JS local dir missing (#{local_dir}), skipping controller checks")
              timings[:http_js] = now - t
              return
            end

            Dir.glob(File.join(local_dir.to_s, "*.js")).each do |path|
              filename = File.basename(path)
              full_path = "#{config[:js_public_prefix]}/#{filename}"
              code, body = http_fetch(full_path, port)

              if code == 200 && !body.to_s.strip.empty?
                UI.ok("#{filename} via #{full_path}")
              else
                detail = code.nil? ? body : "HTTP #{code}"
                http_failures << {
                  category: "js_controller",
                  path: full_path,
                  detail: detail
                }
                UI.error("JS controller asset missing/broken: #{filename} – #{detail}")
              end
            end

            timings[:http_js] = now - t
          end

          def verify_manifest_assets(manifest, port)
            t = now
            UI.step("Validating fingerprinted manifest assets via HTTP")

            digest_paths =
              if manifest.is_a?(Hash)
                manifest.values.grep(String)
              else
                []
              end

            digest_paths.each do |digest|
              full_path = "/assets/#{digest}"
              code, body = http_fetch(full_path, port)

              if code == 200 && !body.to_s.strip.empty?
                UI.ok(full_path)
              else
                detail = code.nil? ? body : "HTTP #{code}"
                http_failures << {
                  category: "manifest",
                  path: full_path,
                  detail: detail
                }
                UI.error("Manifest asset missing/broken: #{full_path} – #{detail}")
              end
            end

            timings[:http_manifest] = now - t
          end
        end
      end
    end
  end
end
