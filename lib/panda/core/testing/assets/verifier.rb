# frozen_string_literal: true

require "json"
require "webrick"
require "net/http"

module Panda
  module Core
    module Testing
      module Assets
        class Verifier
          attr_reader :config, :report

          def initialize(config, report)
            @config = config
            @report = report
          end

          def verify!
            ok = true

            basic_ok = report.time(:basic_files) { basic_checks }
            report.check(:verify_basic_files, basic_ok)
            ok &&= basic_ok

            manifest, importmap = nil, nil
            if basic_ok
              manifest, importmap = report.time(:parse_json) { parse_json }
              json_ok = !manifest.nil? && !importmap.nil?
              report.check(:verify_parse_json, json_ok)
              ok &&= json_ok
            end

            server = nil
            port = 4579

            if ok
              server = start_http_server(port)
              sleep 0.4

              import_ok = report.time(:http_importmap) { verify_importmap(importmap, port) }
              report.check(:verify_http_importmap, import_ok)
              ok &&= import_ok

              js_ok = report.time(:http_js) { verify_js_controllers(port) }
              report.check(:verify_http_js, js_ok)
              ok &&= js_ok

              manifest_ok = report.time(:http_manifest) { verify_manifest_assets(manifest, port) }
              report.check(:verify_http_manifest, manifest_ok)
              ok &&= manifest_ok

              report.time(:http_checks) { ok }
            end

            ok
          ensure
            server&.shutdown
          end

          private

          def assets_dir
            config.dummy_root.join("public/assets")
          end

          def basic_checks
            report.section("#{config.engine_label}: Basic asset checks")

            if Dir.exist?(assets_dir)
              report.log("   ✓ public/assets exists: #{assets_dir}")
            else
              report.log("   ✗ public/assets missing: #{assets_dir}")
              return false
            end

            manifest_path = assets_dir.join(".manifest.json")
            importmap_path = assets_dir.join("importmap.json")

            if File.exist?(manifest_path)
              report.log("   ✓ .manifest.json present")
            else
              report.log("   ✗ .manifest.json missing (Propshaft did not compile)")
              return false
            end

            if File.exist?(importmap_path)
              report.log("   ✓ importmap.json present")
            else
              report.log("   ✗ importmap.json missing")
              return false
            end

            true
          end

          def parse_json
            report.section("#{config.engine_label}: JSON validation")

            manifest_path = assets_dir.join(".manifest.json")
            importmap_path = assets_dir.join("importmap.json")

            manifest = JSON.parse(File.read(manifest_path))
            importmap_raw = File.read(importmap_path)

            # importmap.to_json may already be a JSON string of the full importmap;
            # try to parse; if it fails, treat as object (already JSON)
            importmap = begin
              JSON.parse(importmap_raw)
            rescue JSON::ParserError
              importmap_raw # fallback – later code defensively handles non-Hash
            end

            manifest_size = manifest.is_a?(Hash) ? manifest.size : 0
            import_count =
              if importmap.is_a?(Hash) && importmap["imports"].is_a?(Hash)
                importmap["imports"].size
              else
                0
              end

            report.log("   ✓ Parsed manifest.json (#{manifest_size} entries)")
            report.log("   ✓ Parsed importmap.json (#{import_count} imports)")

            [manifest, importmap]
          rescue => e
            report.log("   ✗ Failed to parse manifest/importmap JSON: #{e.class}: #{e.message}")
            [nil, nil]
          end

          def start_http_server(port)
            report.section("#{config.engine_label}: HTTP checks")

            root = config.dummy_root.join("public").to_s
            report.log("• Starting mini WEBrick server on http://127.0.0.1:#{port} (root: #{root})")

            server = WEBrick::HTTPServer.new(
              Port: port,
              DocumentRoot: root,
              AccessLog: [],
              Logger: WEBrick::Log.new(File::NULL)
            )

            Thread.new { server.start }
            server
          end

          def http_fetch(path, port)
            uri = URI("http://127.0.0.1:#{port}#{path}")
            res = Net::HTTP.get_response(uri)
            return [:ok, res.body] if res.is_a?(Net::HTTPSuccess)

            [:error, res.code]
          rescue => e
            [:exception, e.message]
          end

          def verify_importmap(importmap, port)
            report.log("• Validating importmap assets via HTTP")

            unless importmap.is_a?(Hash) && importmap["imports"].is_a?(Hash)
              report.log("   ! Importmap has no 'imports' hash; skipping HTTP checks for imports")
              return true
            end

            ok = true

            importmap["imports"].each do |logical, path|
              res, data = http_fetch("/assets/#{path}", port)

              case res
              when :ok
                if data.strip.empty?
                  report.log("   ✗ Empty asset for #{logical}")
                  ok = false
                else
                  report.log("   ✓ #{logical} → /assets/#{path}")
                end
              when :error
                report.log("   ✗ Missing importmap asset #{logical} (HTTP #{data})")
                ok = false
              when :exception
                report.log("   ✗ Fetch error for #{logical}: #{data}")
                ok = false
              end
            end

            ok
          end

          def verify_js_controllers(port)
            report.log("• Validating JS controllers (engine-level)")

            root = config.dummy_root.join("app/javascript", config.engine_js_subpath)
            unless root.directory?
              report.log("   ! JS root not found: #{root} – skipping JS checks")
              return true
            end

            ok = true

            # check top-level .js plus controllers/*.js
            js_files = Dir.glob(root.join("*.js")) +
              Dir.glob(root.join("controllers", "*.js"))

            js_files.each do |file|
              basename = File.basename(file)
              # files are served under /assets/<subpath>/<file>
              path = "/assets/#{config.engine_js_subpath}/#{basename}"

              res, data = http_fetch(path, port)

              case res
              when :ok
                if data.strip.empty?
                  report.log("   ✗ JS asset empty: #{path}")
                  ok = false
                else
                  report.log("   ✓ #{basename} (#{path})")
                end
              else
                report.log("   ✗ JS controller asset missing/broken: #{basename} – #{res} #{data}")
                ok = false
              end
            end

            ok
          end

          def verify_manifest_assets(manifest, port)
            report.log("• Validating fingerprinted manifest assets via HTTP")

            return true unless manifest.is_a?(Hash)

            ok = true

            manifest.keys.each do |digest_file|
              # only check fingerprinted assets (with a dash)
              next unless digest_file.include?("-")

              res, data = http_fetch("/assets/#{digest_file}", port)

              case res
              when :ok
                if data.strip.empty?
                  report.log("   ✗ Fingerprinted asset empty: #{digest_file}")
                  ok = false
                else
                  report.log("   ✓ #{digest_file}")
                end
              else
                report.log("   ✗ Missing fingerprinted asset #{digest_file} – #{res} #{data}")
                ok = false
              end
            end

            ok
          end
        end
      end
    end
  end
end
