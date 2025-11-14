# frozen_string_literal: true

require "json"
require "net/http"
require "webrick"

module Panda
  module Core
    module Testing
      module Assets
        class Verifier
          attr_reader :engine, :dummy_root, :timings, :manifest, :importmap

          def initialize(engine)
            @engine = engine.to_sym
            @timings = {}
            @dummy_root = resolve_dummy_root
          end

          def resolve_dummy_root
            root = Rails.root
            return root if root.basename.to_s == "dummy"

            candidate = root.join("spec/dummy")
            return candidate if candidate.exist?

            raise "❌ Could not locate dummy root (looked for #{candidate})"
          end

          # --------------------------------------------------------------
          # Entry point: verify all parts
          # --------------------------------------------------------------

          def verify
            step(:basic_files) { verify_basic_files }
            step(:parse_json) { load_json_files }

            start_server do |port|
              step(:http_importmap) { verify_importmap_assets(port) }
              step(:http_js) { verify_engine_js(port) }
              step(:http_manifest) { verify_manifest_assets(port) }
            end
          end

          # --------------------------------------------------------------
          # Basic presence checks
          # --------------------------------------------------------------

          def verify_basic_files
            assets = dummy_root.join("public/assets")
            raise "❌ public/assets missing" unless assets.exist?

            manifest_path = assets.join(".manifest.json")
            raise "❌ .manifest.json missing" unless manifest_path.exist?

            importmap_path = assets.join("importmap.json")
            raise "❌ importmap.json missing" unless importmap_path.exist?

            puts "   ✓ Basic files present"
          end

          # --------------------------------------------------------------
          # JSON loading
          # --------------------------------------------------------------

          def load_json_files
            assets = dummy_root.join("public/assets")

            manifest_path = assets.join(".manifest.json")
            importmap_path = assets.join("importmap.json")

            @manifest = JSON.parse(File.read(manifest_path))
            @importmap = JSON.parse(File.read(importmap_path))

            puts "   ✓ Parsed manifest.json (#{manifest.size} entries)"
            puts "   ✓ Parsed importmap.json (#{(importmap["imports"] || {}).size} imports)"
          rescue JSON::ParserError => e
            raise "❌ Invalid JSON: #{e.message}"
          end

          # --------------------------------------------------------------
          # HTTP server wrapper
          # --------------------------------------------------------------

          def start_server
            server_port = 4579

            server_thread = Thread.new do
              root = dummy_root.join("public").to_s
              server = WEBrick::HTTPServer.new(
                Port: server_port,
                DocumentRoot: root,
                Logger: WEBrick::Log.new(File::NULL),
                AccessLog: []
              )
              server.start
            end

            sleep 0.4
            yield server_port
          ensure
            Thread.kill(server_thread) if server_thread
          end

          # --------------------------------------------------------------
          # HTTP helpers
          # --------------------------------------------------------------

          def http_get(path, port)
            uri = URI("http://127.0.0.1:#{port}#{path}")
            res = Net::HTTP.get_response(uri)

            return [:ok, res.body] if res.is_a?(Net::HTTPSuccess)
            [:error, res.code]
          rescue => e
            [:exception, e.message]
          end

          # --------------------------------------------------------------
          # Importmap verification
          # --------------------------------------------------------------

          def verify_importmap_assets(port)
            imports = importmap["imports"]
            if imports.nil? || imports.empty?
              puts "   ! No importmap imports (skipping)"
              return
            end

            imports.each do |logical, path|
              res, data = http_get("/assets/#{path}", port)

              case res
              when :ok
                raise "❌ Empty importmap asset #{logical}" if data.strip.empty?
                puts "   ✓ #{logical} -> #{path}"
              when :error
                raise "❌ Missing importmap asset #{logical} (HTTP #{data})"
              when :exception
                raise "❌ Error fetching #{logical}: #{data}"
              end
            end
          end

          # --------------------------------------------------------------
          # Engine JS verification
          # --------------------------------------------------------------

          def verify_engine_js(port)
            js_root = dummy_root.join("app/javascript/panda/#{engine}")
            return unless js_root.exist?

            controllers = Dir.glob(js_root.join("*.js")).map { |f| File.basename(f) }

            controllers.each do |logical|
              res, data = http_get("/assets/panda/#{engine}/#{logical}", port)

              case res
              when :ok
                raise "❌ Empty JS file #{logical}" if data.strip.empty?
                puts "   ✓ JS #{logical}"
              else
                raise "❌ JS asset missing/broken: #{logical}"
              end
            end
          end

          # --------------------------------------------------------------
          # Fingerprinted Propshaft verification
          # --------------------------------------------------------------

          def verify_manifest_assets(port)
            manifest.each_key do |digest_path|
              next unless digest_path.include?("-")

              res, data = http_get("/assets/#{digest_path}", port)

              case res
              when :ok
                raise "❌ Empty digest asset #{digest_path}" if data.strip.empty?
                puts "   ✓ #{digest_path}"
              else
                raise "❌ Missing digest asset #{digest_path}"
              end
            end
          end

          # --------------------------------------------------------------
          # Timing wrapper
          # --------------------------------------------------------------

          def step(name)
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            yield
            finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            timings[name] = (finish - start).round(3)
          rescue => e
            timings[name] = :failed
            raise e
          end
        end
      end
    end
  end
end
