# frozen_string_literal: true

require "json"
require "webrick"
require "net/http"
require "benchmark"
require "fileutils"
require_relative "ui"
require_relative "html_report"

module Panda
  module Assets
    class Verifier
      Result = Struct.new(
        :ok,
        :timings,
        :checks,
        :dummy_root,
        :engine_key,
        :errors,
        :js_resolution,
        keyword_init: true
      )

      attr_reader :engine_key, :config, :dummy_root, :timings, :errors, :checks, :js_resolution

      # config keys:
      #   :dummy_root         Pathname
      #   :engine_js_roots    [Array<Pathname>] (app/javascript & vendor/javascript)
      #   :engine_js_prefix   String, logical prefix for JS (e.g. "panda/core", "panda/cms")
      def initialize(engine_key, config)
        @engine_key = engine_key
        @config = config
        @dummy_root = config.fetch(:dummy_root)
        @timings = {}
        @errors = []
        @checks = {}       # { check_name => true/false }
        @js_resolution = {} # { logical => { sources: [path], chosen: path } }
      end

      def verify
        Panda::Assets::UI.banner("Verifying dummy assets (#{engine_label})")

        manifest_path = dummy_root.join("public/assets/.manifest.json")
        importmap_path = dummy_root.join("public/assets/importmap.json")

        manifest = nil
        importmap = nil

        time(:basic_files) do
          manifest, importmap = basic_file_checks(manifest_path, importmap_path)
        end

        time(:parse_json) do
          manifest, importmap = parse_json(manifest_path, importmap_path, manifest, importmap)
        end

        port = nil
        server_thread = nil

        time(:http_checks) do
          port, server_thread = start_server
          http_checks(manifest, importmap, port)
        end

        stop_server(server_thread)

        ok = checks.values.all? && errors.empty?

        # Build HTML report
        report_path = Panda::Assets::HTMLReport.new(
          engine_key: engine_key,
          dummy_root: dummy_root,
          checks: checks,
          timings: timings,
          manifest: manifest,
          importmap: importmap,
          js_resolution: js_resolution,
          errors: errors
        ).write!

        # Register report path for AssetLoader / CI
        if defined?(Panda::Core::Assets::ReportRegistry)
          Panda::Core::Assets::ReportRegistry.register(report_path)
        end

        Panda::Assets::UI.step "HTML report written to #{report_path}"

        Result.new(
          ok: ok,
          timings: timings,
          checks: checks,
          dummy_root: dummy_root,
          engine_key: engine_key,
          errors: errors.dup,
          js_resolution: js_resolution
        )
      rescue => e
        errors << "Unexpected verifier error: #{e.class}: #{e.message}"
        Result.new(
          ok: false,
          timings: timings,
          checks: checks,
          dummy_root: dummy_root,
          engine_key: engine_key,
          errors: errors.dup,
          js_resolution: js_resolution
        )
      end

      private

      def engine_label
        "Panda #{engine_key.to_s.split("_").map(&:capitalize).join(" ")}"
      end

      def time(key)
        timings[key] = Benchmark.realtime { yield }.round(2)
      end

      def mark(check, value, msg = nil)
        checks[check] = value
        if value
          Panda::Assets::UI.ok msg if msg
        elsif msg
          Panda::Assets::UI.error msg
        end
      end

      def basic_file_checks(manifest_path, importmap_path)
        Panda::Assets::UI.banner("#{engine_label}: Basic asset checks")

        assets_dir = dummy_root.join("public/assets")
        unless assets_dir.directory?
          mark(:assets_dir, false, "public/assets missing at #{assets_dir}")
          errors << "public/assets missing"
          return [nil, nil]
        end
        mark(:assets_dir, true, "public/assets exists: #{assets_dir}")

        if manifest_path.exist?
          mark(:manifest_present, true, ".manifest.json present")
        else
          mark(:manifest_present, false, ".manifest.json missing")
          errors << ".manifest.json missing"
        end

        if importmap_path.exist?
          mark(:importmap_present, true, "importmap.json present")
        else
          mark(:importmap_present, false, "importmap.json missing")
          errors << "importmap.json missing"
        end

        [manifest_path.exist? ? {} : nil, importmap_path.exist? ? {} : nil]
      end

      def parse_json(manifest_path, importmap_path, manifest, importmap)
        Panda::Assets::UI.banner("#{engine_label}: JSON validation")

        if manifest_path.exist?
          begin
            manifest = JSON.parse(File.read(manifest_path))
            mark(:manifest_parse, true, "Parsed manifest.json (#{manifest.size} entries)")
          rescue JSON::ParserError => e
            mark(:manifest_parse, false, "Invalid manifest.json: #{e.message}")
            errors << "Invalid manifest.json"
          end
        end

        if importmap_path.exist?
          begin
            raw = JSON.parse(File.read(importmap_path))
            imports = raw["imports"].is_a?(Hash) ? raw["imports"] : {}
            importmap = imports
            mark(:importmap_parse, true, "Parsed importmap.json (#{importmap.size} imports)")
          rescue JSON::ParserError => e
            mark(:importmap_parse, false, "Invalid importmap.json: #{e.message}")
            errors << "Invalid importmap.json"
          end
        end

        [manifest || {}, importmap || {}]
      end

      def start_server
        Panda::Assets::UI.banner("#{engine_label}: HTTP checks")

        root = dummy_root.join("public").to_s
        port = ENV.fetch("PANDA_ASSETS_HTTP_PORT", "4579").to_i

        server = WEBrick::HTTPServer.new(
          Port: port,
          DocumentRoot: root,
          AccessLog: [],
          Logger: WEBrick::Log.new(File::NULL)
        )

        thread = Thread.new { server.start }

        sleep 0.4

        Panda::Assets::UI.step "Starting mini WEBrick server on http://127.0.0.1:#{port} (root: #{root})"

        [port, thread]
      rescue => e
        errors << "Failed to start WEBrick: #{e.class}: #{e.message}"
        [nil, nil]
      end

      def stop_server(thread)
        Thread.kill(thread) if thread&.alive?
      rescue
        # ignore
      end

      def http_fetch(path, port)
        uri = URI("http://127.0.0.1:#{port}#{path}")
        res = Net::HTTP.get_response(uri)

        if res.is_a?(Net::HTTPSuccess)
          [:ok, res.body]
        else
          [:error, res.code]
        end
      rescue => e
        [:exception, e.message]
      end

      def http_checks(manifest, importmap, port)
        return unless port

        time(:http_importmap) { verify_importmap_assets(importmap, port) }
        time(:http_js) { verify_js_controllers(manifest, port) }
        time(:http_manifest) { verify_manifest_assets(manifest, port) }

        checks[:http_checks] = checks.fetch(:http_importmap, true) &&
          checks.fetch(:http_js, true) &&
          checks.fetch(:http_manifest, true)
      end

      def verify_importmap_assets(importmap, port)
        Panda::Assets::UI.step "Validating importmap assets via HTTP"

        if importmap.empty?
          Panda::Assets::UI.warn "Importmap has no imports; skipping HTTP checks for imports"
          checks[:http_importmap] = true
          return
        end

        all_ok = true

        importmap.each do |name, path|
          next unless path

          normalized = path.start_with?("/") ? path : "/assets/#{path}"
          status, body = http_fetch(normalized, port)

          case status
          when :ok
            if body.to_s.strip.empty?
              Panda::Assets::UI.error "Empty asset for import '#{name}' at #{normalized}"
              all_ok = false
            else
              Panda::Assets::UI.ok "#{name} → #{normalized}"
            end
          when :error
            Panda::Assets::UI.error "Missing import '#{name}' at #{normalized} (HTTP #{body})"
            all_ok = false
          when :exception
            Panda::Assets::UI.error "Error fetching import '#{name}': #{body}"
            all_ok = false
          end
        end

        checks[:http_importmap] = all_ok
      end

      # Scan app/javascript & vendor/javascript and resolve latest version per logical
      def js_sources
        roots = Array(config[:engine_js_roots]).compact
        return [] if roots.empty?

        logical_prefix = config[:engine_js_prefix] || "panda/#{engine_key}"

        candidates = {}

        roots.each do |root|
          next unless root.directory?

          Dir.glob(root.join("**/*.js")).each do |file|
            # Logical path relative to app/javascript or vendor/javascript root
            rel = Pathname.new(file).relative_path_from(root).to_s
            logical = File.join(logical_prefix, rel).tr("\\", "/")

            candidates[logical] ||= []
            candidates[logical] << file
          end
        end

        # Resolve latest by mtime
        resolved = {}

        candidates.each do |logical, paths|
          chosen = paths.max_by { |p|
            begin
              File.mtime(p)
            rescue
              Time.at(0)
            end
          }
          resolved[logical] = {
            "sources" => paths,
            "chosen" => chosen
          }
        end

        @js_resolution = resolved
        resolved.keys
      end

      def verify_js_controllers(manifest, port)
        Panda::Assets::UI.step "Validating JS controllers (engine-level)"

        logicals = js_sources
        if logicals.empty?
          Panda::Assets::UI.warn "No engine JS roots configured; skipping JS controller HTTP checks"
          checks[:http_js] = true
          return
        end

        all_ok = true

        logicals.each do |logical|
          digest = manifest[logical] || logical

          path = digest.start_with?("/") ? digest : "/assets/#{digest}"

          status, body = http_fetch(path, port)

          case status
          when :ok
            if body.to_s.strip.empty?
              Panda::Assets::UI.error "JS asset empty: #{logical} (#{path})"
              all_ok = false
            else
              Panda::Assets::UI.ok "JS OK: #{logical} → #{path}"
            end
          when :error
            Panda::Assets::UI.error "JS asset missing/broken: #{logical} – HTTP #{body}"
            all_ok = false
          when :exception
            Panda::Assets::UI.error "JS fetch error: #{logical} – #{body}"
            all_ok = false
          end
        end

        checks[:http_js] = all_ok
      end

      def verify_manifest_assets(manifest, port)
        Panda::Assets::UI.step "Validating fingerprinted manifest assets via HTTP"

        if manifest.empty?
          Panda::Assets::UI.warn "Manifest is empty; skipping fingerprinted asset checks"
          checks[:http_manifest] = true
          return
        end

        values = manifest.values.uniq
        all_ok = true

        values.each do |digest_file|
          digest_file = digest_file.to_s
          next unless digest_file.include?("-") # heuristic: fingerprinted

          path = "/assets/#{digest_file}"
          status, body = http_fetch(path, port)

          case status
          when :ok
            if body.to_s.strip.empty?
              Panda::Assets::UI.error "Fingerprinted asset empty: #{digest_file}"
              all_ok = false
            else
              Panda::Assets::UI.ok "Fingerprinted OK: #{digest_file}"
            end
          when :error
            Panda::Assets::UI.error "Missing fingerprinted asset #{digest_file} – HTTP #{body}"
            all_ok = false
          when :exception
            Panda::Assets::UI.error "Error fetching fingerprinted asset #{digest_file}: #{body}"
            all_ok = false
          end
        end

        checks[:http_manifest] = all_ok
      end
    end
  end
end
