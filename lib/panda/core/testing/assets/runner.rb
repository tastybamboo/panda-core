# frozen_string_literal: true

require "benchmark"
require "erb"
require "fileutils"
require "json"
require "pathname"
require "webrick"

module Panda
  module Core
    module Testing
      module Assets
        # Unified asset pipeline runner for Panda engines
        #
        # Responsibilities:
        #   • Run the dummy app Propshaft pipeline
        #   • Copy engine JavaScript into the dummy app (if desired)
        #   • Generate importmap.json for the dummy app
        #   • Verify manifest + importmap correctness
        #   • Perform HTTP-level checks using a tiny WEBrick server
        #   • Produce an HTML report (with JS version resolution)
        #   • Optionally embed the HTML report into GitHub step summary
        #
        class Runner
          CheckResult = Struct.new(:ok, :message, keyword_init: true)

          attr_reader :kind, :label, :dummy_root, :assets_dir, :report_path, :checks, :timings

          def initialize(kind = :core)
            @kind = kind.to_sym
            @label = kind_label(@kind)
            @dummy_root = find_dummy_root
            @assets_dir = @dummy_root.join("public/assets")
            @tmp_dir = @dummy_root.join("tmp")
            FileUtils.mkdir_p(@tmp_dir)
            @report_path = @tmp_dir.join("panda_assets_report.html")

            @checks = {}
            @timings = Hash.new(0.0)

            @manifest = nil
            @importmap = nil
            @js_choice = nil # { logical_name => { chosen: {...}, discarded: [...] } }
          end

          # ------------------------------------------------------------------
          # Public interface
          # ------------------------------------------------------------------

          def prepare
            banner("Preparing dummy assets (#{label})")

            time("propshaft") do
              compile_propshaft_assets
            end

            time("copy_js") do
              copy_engine_js
            end

            time("importmap_generate") do
              generate_importmap
            end

            checks[:prepare] = CheckResult.new(ok: true, message: "Prepare phase OK")
          rescue => e
            checks[:prepare] = CheckResult.new(ok: false, message: "Prepare failed: #{e.message}")
            raise
          ensure
            timings["total_prepare"] = timings.values_at("propshaft", "copy_js", "importmap_generate").compact.sum
          end

          def verify
            banner("Verifying dummy assets (#{label})")

            time("basic_files") do
              verify_basic_files
            end

            time("parse_json") do
              load_manifest_and_importmap
              resolve_js_versions_for_report
            end

            time("http_checks") do
              http_checks
            end

            checks[:verify] = CheckResult.new(ok: true, message: "Verify phase OK")
          rescue => e
            checks[:verify] = CheckResult.new(ok: false, message: "Verify failed: #{e.message}")
            raise
          ensure
            timings["total_verify"] = timings.values_at("basic_files", "parse_json", "http_checks").compact.sum
          end

          def run
            prepare_ok = false
            verify_ok = false

            begin
              prepare
              prepare_ok = true
              verify
              verify_ok = true
            rescue => e
              warn "❌ #{label} assets pipeline failed: #{e.class}: #{e.message}"
            ensure
              write_html_report(prepare_ok: prepare_ok, verify_ok: verify_ok)
              write_github_summary_snippet

              puts "• HTML report written to #{report_path}"

              exit 1 unless prepare_ok && verify_ok
            end
          end

          # ------------------------------------------------------------------
          # Internal helpers
          # ------------------------------------------------------------------

          private

          def kind_label(kind)
            case kind.to_sym
            when :core then "Panda Core"
            when :cms then "Panda CMS"
            else kind.to_s
            end
          end

          def banner(text)
            width = text.length + 4
            line = "┌" + "─" * (width - 2) + "┐"
            mid = "│ #{text} │"
            bottom = "└" + "─" * (width - 2) + "┘"
            puts line
            puts mid
            puts bottom
          end

          def time(key)
            timings[key] = Benchmark.realtime { yield }.round(2)
          end

          # -- dummy root & paths ------------------------------------------------

          def find_dummy_root
            root = Rails.root
            return root if root.basename.to_s == "dummy"

            candidate = root.join("spec/dummy")
            return candidate if candidate.exist?

            raise "❌ Cannot find dummy root – expected #{candidate}"
          end

          def dummy_config_environment
            dummy_root.join("config/environment")
          end

          # ----------------------------------------------------------------------
          # PREPARE PHASE
          # ----------------------------------------------------------------------

          def compile_propshaft_assets
            puts "• Compiling Propshaft assets in dummy app (RAILS_ENV=test)"

            Dir.chdir(dummy_root) do
              # Propshaft compile
              success = system("bundle exec rails assets:precompile RAILS_ENV=test")
              raise "Failed to compile Propshaft assets" unless success
            end

            puts "   ✓ Propshaft assets compiled"
          end

          def copy_engine_js
            puts "• Copying engine JS modules into dummy app"

            copied = []

            # Always include Panda Core JS
            copied.concat(copy_engine_js_for(Panda::Core::Engine, namespace: "panda/core"))

            # Include any registered modules (CMS, etc.) if ModuleRegistry is available
            if defined?(Panda::Core::ModuleRegistry)
              Panda::Core::ModuleRegistry.modules.each do |gem_name, info|
                engine_class = safe_const_get(info[:engine])
                next unless engine_class

                rel = "panda/#{gem_name.sub(/^panda-/, "")}"
                copied.concat(copy_engine_js_for(engine_class, namespace: rel))
              end
            end

            if copied.empty?
              puts "   ! No engine JS modules found to copy"
            else
              copied.uniq!
              copied.each { |entry| puts "   ✓ Copied JS from #{entry[:from]} to #{entry[:to]}" }
            end
          end

          def copy_engine_js_for(engine_class, namespace:)
            engine_root = engine_class.root
            source_dir = engine_root.join("app/javascript", namespace)
            return [] unless source_dir.directory?

            dest_dir = dummy_root.join("app/javascript", namespace)
            FileUtils.mkdir_p(dest_dir)

            copied = []
            Dir.glob(source_dir.join("**/*.js")).each do |path|
              rel = Pathname.new(path).relative_path_from(source_dir)
              dest = dest_dir.join(rel)
              FileUtils.mkdir_p(dest.dirname)
              FileUtils.cp(path, dest)
              copied << {from: source_dir.to_s, to: dest_dir.to_s}
            end

            copied
          end

          def generate_importmap
            puts "• Generating importmap.json from dummy Rails app"

            Dir.chdir(dummy_root) do
              require dummy_config_environment.to_s

              raw = Rails.application.importmap.to_json

              hash =
                case raw
                when String
                  JSON.parse(raw)
                when Hash
                  raw
                else
                  {}
                end

              FileUtils.mkdir_p(assets_dir)
              path = assets_dir.join("importmap.json")
              File.write(path, JSON.pretty_generate(hash))

              puts "   ✓ Wrote #{path}"
            end
          end

          # ----------------------------------------------------------------------
          # VERIFY PHASE
          # ----------------------------------------------------------------------

          def verify_basic_files
            FileUtils.mkdir_p(assets_dir)

            manifest_path = assets_dir.join(".manifest.json")
            importmap_path = assets_dir.join("importmap.json")

            ok = true

            if Dir.exist?(assets_dir)
              puts "   ✓ public/assets exists: #{assets_dir}"
            else
              puts "   ✗ public/assets missing: #{assets_dir}"
              ok = false
            end

            if File.exist?(manifest_path)
              puts "   ✓ .manifest.json present"
            else
              puts "   ✗ .manifest.json missing"
              ok = false
            end

            if File.exist?(importmap_path)
              puts "   ✓ importmap.json present"
            else
              puts "   ✗ importmap.json missing"
              ok = false
            end

            raise ".manifest.json or importmap.json missing" unless ok
          end

          def load_manifest_and_importmap
            manifest_path = assets_dir.join(".manifest.json")
            importmap_path = assets_dir.join("importmap.json")

            @manifest = JSON.parse(File.read(manifest_path))
            puts "   ✓ Parsed manifest.json (#{@manifest.size} entries)"

            raw_importmap = JSON.parse(File.read(importmap_path))
            # importmap JSON from importmap-rails has shape: { "imports" => { ... } }
            @importmap = raw_importmap.is_a?(Hash) ? raw_importmap : {}
            import_count = @importmap["imports"].is_a?(Hash) ? @importmap["imports"].size : 0
            puts "   ✓ Parsed importmap.json (#{import_count} imports)"
          rescue JSON::ParserError => e
            raise "Invalid JSON in manifest or importmap: #{e.message}"
          end

          # ----------------------------------------------------------------------
          # JS VERSION RESOLUTION (for reporting)
          # ----------------------------------------------------------------------

          def resolve_js_versions_for_report
            candidates = collect_js_candidates

            grouped = candidates.group_by { |h| logical_name_for(h[:path]) }

            @js_choice = {}

            grouped.each do |logical, files|
              chosen = files.max_by { |h| version_sort_key(h[:path]) }
              discarded = files - [chosen]

              @js_choice[logical] = {
                chosen: chosen,
                discarded: discarded
              }
            end
          end

          def collect_js_candidates
            list = []

            # Core engine
            list.concat(collect_engine_js_candidates(Panda::Core::Engine, source: "panda-core"))

            # Registered modules (e.g. panda-cms)
            if defined?(Panda::Core::ModuleRegistry)
              Panda::Core::ModuleRegistry.modules.each do |gem_name, info|
                engine_class = safe_const_get(info[:engine])
                next unless engine_class

                list.concat(collect_engine_js_candidates(engine_class, source: gem_name))
              end
            end

            list
          end

          def collect_engine_js_candidates(engine_class, source:)
            root = engine_class.root

            paths = []
            app_js_root = root.join("app/javascript")
            vendor_js_root = root.join("vendor/javascript")

            if app_js_root.directory?
              Dir.glob(app_js_root.join("**/*.js")).each do |p|
                paths << {path: p, source: source, kind: :app}
              end
            end

            if vendor_js_root.directory?
              Dir.glob(vendor_js_root.join("**/*.js")).each do |p|
                paths << {path: p, source: source, kind: :vendor}
              end
            end

            paths
          end

          def logical_name_for(path)
            filename = File.basename(path)
            # strip "-x.y.z" if present
            filename.sub(/-\d+\.\d+\.\d+/, "")
          end

          def extract_version(path)
            filename = File.basename(path)
            if filename =~ /-(\d+\.\d+\.\d+)/
              Gem::Version.new(Regexp.last_match(1))
            end
          end

          def version_sort_key(path)
            extract_version(path) || File.mtime(path)
          end

          # ----------------------------------------------------------------------
          # HTTP CHECKS
          # ----------------------------------------------------------------------

          def http_checks
            return unless @manifest && @importmap

            puts "• Starting mini WEBrick server on http://127.0.0.1:4579 (root: #{dummy_root.join("public")})"

            server = WEBrick::HTTPServer.new(
              Port: 4579,
              DocumentRoot: dummy_root.join("public").to_s,
              AccessLog: [],
              Logger: WEBrick::Log.new(File::NULL)
            )

            server_thread = Thread.new { server.start }
            sleep 0.4 # give it a moment

            begin
              time("http_importmap") { http_check_importmap_assets }
              time("http_manifest") { http_check_manifest_assets }
              timings["http_checks"] = timings["http_importmap"] + timings["http_manifest"]
            ensure
              server.shutdown
              server_thread.kill
            end
          end

          def http_check_importmap_assets
            imports = @importmap["imports"]
            if !imports.is_a?(Hash) || imports.empty?
              puts "• Validating importmap assets via HTTP"
              puts "   ! Importmap has no 'imports' hash; skipping HTTP checks for imports"
              return
            end

            puts "• Validating importmap assets via HTTP"

            imports.each do |logical_name, path|
              res, data = http_fetch("/assets/#{path}")

              case res
              when :ok
                if data.strip.empty?
                  raise "Empty asset for importmap entry #{logical_name} (#{path})"
                end
                puts "   ✓ #{logical_name} → /assets/#{path}"
              when :error
                raise "Missing importmap asset #{logical_name} (HTTP #{data})"
              when :exception
                raise "Error fetching importmap asset #{logical_name}: #{data}"
              end
            end
          end

          def http_check_manifest_assets
            puts "• Validating fingerprinted manifest assets via HTTP"

            @manifest.keys.each do |digest_path|
              # Only fingerprinted entries (contain dash before extension)
              next unless digest_path.include?("-")

              res, data = http_fetch("/assets/#{digest_path}")

              case res
              when :ok
                raise "Empty fingerprinted asset #{digest_path}" if data.strip.empty?
                puts "   ✓ #{digest_path}"
              when :error
                raise "Missing fingerprinted asset #{digest_path} (HTTP #{data})"
              when :exception
                raise "Error fetching fingerprinted asset #{digest_path}: #{data}"
              end
            end
          end

          def http_fetch(path)
            require "net/http"

            uri = URI("http://127.0.0.1:4579#{path}")
            res = Net::HTTP.get_response(uri)

            return [:ok, res.body] if res.is_a?(Net::HTTPSuccess)
            [:error, res.code]
          rescue => e
            [:exception, e.message]
          end

          # ----------------------------------------------------------------------
          # REPORTING
          # ----------------------------------------------------------------------

          def write_html_report(prepare_ok:, verify_ok:)
            FileUtils.mkdir_p(@tmp_dir)

            html = +""
            html << "<!DOCTYPE html>\n<html>\n<head>\n"
            html << "  <meta charset=\"utf-8\" />\n"
            html << "  <title>#{label} – dummy asset report</title>\n"
            html << "  <style>\n"
            html << "    body { font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 1.5rem; line-height: 1.5; }\n"
            html << "    h1, h2, h3 { margin-top: 1.5rem; }\n"
            html << "    .ok { color: #15803d; font-weight: 600; }\n"
            html << "    .fail { color: #b91c1c; font-weight: 600; }\n"
            html << "    table { border-collapse: collapse; width: 100%; margin-top: 0.75rem; }\n"
            html << "    th, td { border: 1px solid #e5e7eb; padding: 0.4rem 0.6rem; font-size: 0.9rem; }\n"
            html << "    th { background: #f9fafb; text-align: left; }\n"
            html << "    code { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace; font-size: 0.85rem; }\n"
            html << "    .badge { display: inline-block; padding: 0.1rem 0.4rem; border-radius: 999px; font-size: 0.75rem; background: #e5e7eb; }\n"
            html << "  </style>\n"
            html << "</head>\n<body>\n"

            html << "<h1>#{label} – dummy asset report</h1>\n"

            html << "<p>\n"
            html << "  Prepare: <span class=\"#{prepare_ok ? "ok" : "fail"}\">#{prepare_ok ? "OK" : "FAILED"}</span><br/>\n"
            html << "  Verify:  <span class=\"#{verify_ok ? "ok" : "fail"}\">#{verify_ok ? "OK" : "FAILED"}</span>\n"
            html << "</p>\n"

            html << "<h2>Checks</h2>\n"
            html << "<table>\n"
            html << "<thead><tr><th>Check</th><th>Status</th><th>Message</th></tr></thead>\n<tbody>\n"

            checks.each do |key, result|
              status = result&.ok ? "OK" : "FAILED"
              css = result&.ok ? "ok" : "fail"
              html << "<tr><td><code>#{key}</code></td><td class=\"#{css}\">#{status}</td><td>#{ERB::Util.html_escape(result&.message || "")}</td></tr>\n"
            end

            html << "</tbody>\n</table>\n"

            html << "<h2>Timings</h2>\n"
            html << "<table>\n"
            html << "<thead><tr><th>Stage</th><th>Seconds</th></tr></thead>\n<tbody>\n"
            timings.sort_by { |k, _| k.to_s }.each do |stage, secs|
              html << "<tr><td><code>#{stage}</code></td><td>#{secs}</td></tr>\n"
            end
            html << "</tbody>\n</table>\n"

            if @js_choice && !@js_choice.empty?
              html << "<h2>JavaScript versions (engines + vendor/javascript)</h2>\n"
              html << "<table>\n"
              html << "<thead><tr><th>Logical name</th><th>Chosen file</th><th>Source</th><th>Kind</th><th>Version / mtime</th><th>Discarded</th></tr></thead>\n<tbody>\n"

              @js_choice.sort_by { |logical, _| logical.to_s }.each do |logical, data|
                chosen = data[:chosen]
                discarded = data[:discarded] || []

                chosen_ver = extract_version(chosen[:path]) || File.mtime(chosen[:path])

                discarded_html = discarded.map do |d|
                  ver = extract_version(d[:path]) || File.mtime(d[:path])
                  "⟂ #{ERB::Util.html_escape(d[:source])} (#{ERB::Util.html_escape(d[:kind].to_s)}) – <code>#{ERB::Util.html_escape(d[:path])}</code> [#{ver}]"
                end.join("<br/>")

                html << "<tr>\n"
                html << "  <td><code>#{ERB::Util.html_escape(logical)}</code></td>\n"
                html << "  <td><code>#{ERB::Util.html_escape(chosen[:path])}</code></td>\n"
                html << "  <td><span class=\"badge\">#{ERB::Util.html_escape(chosen[:source])}</span></td>\n"
                html << "  <td><span class=\"badge\">#{ERB::Util.html_escape(chosen[:kind].to_s)}</span></td>\n"
                html << "  <td>#{chosen_ver}</td>\n"
                html << "  <td>#{discarded_html}</td>\n"
                html << "</tr>\n"
              end

              html << "</tbody>\n</table>\n"
            end

            html << "</body>\n</html>\n"

            File.write(report_path, html)
          end

          def write_github_summary_snippet
            summary_path = ENV["GITHUB_STEP_SUMMARY"]
            return unless summary_path && File.exist?(report_path)

            html = File.read(report_path)

            File.open(summary_path, "a") do |f|
              f.puts "\n\n---\n\n"
              f.puts "### #{label} asset report\n"
              f.puts
              # GitHub step summary supports raw HTML
              f.puts html
            end
          rescue => e
            warn "⚠️ Failed to write GitHub step summary: #{e.message}"
          end

          # ----------------------------------------------------------------------
          # Misc helpers
          # ----------------------------------------------------------------------

          def safe_const_get(name)
            return nil unless name
            Object.const_get(name)
          rescue NameError
            nil
          end
        end
      end
    end
  end
end
