# frozen_string_literal: true

#
# Panda Core Asset Tasks
#

namespace :panda do
  namespace :core do
    namespace :assets do
      # =========================================================
      # 1) ENGINE CSS COMPILATION (unchanged, just cleaned)
      # =========================================================

      desc "Compile Panda Core CSS assets (development mode)"
      task :compile do
        puts "🐼 Compiling Panda Core CSS assets..."

        output_dir = panda_engine_root.join("public", "panda-core-assets")
        FileUtils.mkdir_p(output_dir)

        compile_css_development(output_dir)

        puts "🎉 CSS compiled → #{output_dir}"
      end

      desc "Compile and version Panda Core CSS assets for release"
      task :release do
        require_relative "../../panda/core/version"

        version = Panda::Core::VERSION
        output_dir = panda_engine_root.join("public", "panda-core-assets")
        FileUtils.mkdir_p(output_dir)

        compile_css_release(output_dir, version)

        puts "🎉 Release assets compiled"
      end

      # =========================================================
      # CSS INTERNAL HELPERS
      # =========================================================

      def panda_engine_root
        Panda::Core::Engine.root
      end

      def compile_css_development(output_dir)
        input = panda_engine_root.join("app/assets/tailwind/application.css")
        output = output_dir.join("panda-core.css")

        content = Panda::Core::ModuleRegistry.tailwind_content_paths
        flags = content.map { |p| "--content '#{p}'" }.join(" ")

        cmd = "bundle exec tailwindcss -i #{input} -o #{output} #{flags} --minify"
        abort("❌ CSS compile failed") unless system(cmd)

        puts "   ✓ #{output.basename} (#{File.size(output)} bytes)"
      end

      def compile_css_release(output_dir, version)
        input = panda_engine_root.join("app/assets/tailwind/application.css")
        file = output_dir.join("panda-core-#{version}.css")

        content = Panda::Core::ModuleRegistry.tailwind_content_paths
        flags = content.map { |p| "--content '#{p}'" }.join(" ")

        cmd = "bundle exec tailwindcss -i #{input} -o #{file} #{flags} --minify"
        abort("❌ CSS release compile failed") unless system(cmd)

        symlink = output_dir.join("panda-core.css")
        FileUtils.rm_f(symlink)
        FileUtils.ln_sf(file.basename, symlink)

        puts "   ✓ Versioned file + symlink created"
      end

      # =========================================================
      # 2) DUMMY APP PREP (FOR SYSTEM TESTS + CI)
      # =========================================================

      desc "Compile Panda Core + dummy app assets into spec/dummy/public/assets"
      task compile_dummy: :environment do
        dummy_root = find_dummy_root
        assets_root = dummy_root.join("public/assets")

        puts "🚧 Compiling dummy assets..."
        puts "   → #{assets_root}"
        FileUtils.mkdir_p(assets_root)

        Dir.chdir(dummy_root) do
          # IMPORTANT: this is now the correct task name
          unless system("bundle exec rake panda:core:assets:compile")
            abort("❌ panda:core:assets:compile failed in dummy app")
          end

          # Propshaft (Rails 8)
          abort("❌ assets:precompile failed") \
            unless system("bundle exec rake assets:precompile RAILS_ENV=#{Rails.env}")
        end

        puts "✅ Dummy assets compiled"

        puts "📦 Copying Panda Core JavaScript modules..."
        engine_js = Panda::Core::Engine.root.join("app/javascript/panda/core")
        dummy_js = dummy_root.join("app/javascript/panda/core")

        FileUtils.mkdir_p(dummy_js)
        FileUtils.cp_r(engine_js.children, dummy_js)
      end

      desc "Generate importmap.json for the dummy app"
      task generate_dummy_importmap: :environment do
        dummy_root = find_dummy_root
        output = dummy_root.join("public/assets/importmap.json")

        puts "🗺️  Generating importmap.json..."
        FileUtils.mkdir_p(output.dirname)

        Dir.chdir(dummy_root) do
          json = Rails.application.importmap.to_json(
            resolver: ActionController::Base.helpers
          )
          File.write(output, JSON.pretty_generate(json))
        end

        puts "   ✓ importmap.json written"
      end

      desc "Verify dummy app asset readiness (fail-fast for CI with live HTTP checks)"
      task verify_dummy: :environment do
        require "net/http"
        require "json"
        require "webrick"

        dummy_root = find_dummy_root
        assets_root = dummy_root.join("public/assets")
        manifest_path = assets_root.join(".manifest.json")
        importmap_path = assets_root.join("importmap.json")

        puts "🔍 [Panda Core] Verifying dummy asset readiness..."

        abort("❌ Missing directory: #{assets_root}") unless Dir.exist?(assets_root)
        abort("❌ Missing .manifest.json at #{manifest_path}") unless File.exist?(manifest_path)
        abort("❌ Missing importmap.json at #{importmap_path}") unless File.exist?(importmap_path)

        manifest = begin
          JSON.parse(File.read(manifest_path))
        rescue
          abort("❌ Invalid JSON in .manifest.json")
        end
        importmap = begin
          JSON.parse(File.read(importmap_path))
        rescue
          abort("❌ Invalid JSON in importmap.json")
        end

        puts "  ✓ Manifest loaded (#{manifest.size} entries)"
        puts "  ✓ Importmap loaded (#{importmap["imports"].size} imports)"

        # ---------------------------------------------------------------
        # Start a tiny WEBrick server serving dummy/public
        # ---------------------------------------------------------------
        server_port = 4567
        server_thread = Thread.new do
          root = dummy_root.join("public").to_s
          WEBrick::HTTPServer.new(
            Port: server_port,
            DocumentRoot: root,
            AccessLog: [],
            Logger: WEBrick::Log.new(File::NULL)
          ).start
        end

        # Wait a moment for server to boot
        sleep 0.4

        def http_ok?(path, server_port)
          uri = URI("http://127.0.0.1:#{server_port}#{path}")
          res = Net::HTTP.get_response(uri)
          return [:ok, res.body] if res.is_a?(Net::HTTPSuccess)
          [:error, res.code]
        rescue => e
          [:exception, e.message]
        end

        # ---------------------------------------------------------------
        # Validate importmap resolves to existing HTTP assets
        # ---------------------------------------------------------------
        puts "🔍 Checking importmap imports via HTTP..."

        importmap["imports"].each do |logical_name, path|
          res, data = http_ok?("/assets/#{path}", server_port)

          case res
          when :ok
            if data.to_s.strip.empty?
              abort("❌ Empty asset received for #{logical_name} → /assets/#{path}")
            end
            puts "   ✓ #{logical_name} → /assets/#{path}"
          when :error
            abort("❌ Importmap asset missing: #{logical_name} → /assets/#{path} (HTTP #{data})")
          when :exception
            abort("❌ Error fetching #{logical_name}: #{data}")
          end
        end

        # ---------------------------------------------------------------
        # Validate panda-core.css + any fingerprinted versions
        # ---------------------------------------------------------------
        puts "🔍 Checking panda-core CSS assets..."

        # non-fingerprinted
        res, data = http_ok?("/panda-core-assets/panda-core.css", server_port)
        abort("❌ Missing panda-core.css (#{res}: #{data})") unless res == :ok
        abort("❌ panda-core.css is empty") if data.strip.empty?
        puts "   ✓ panda-core.css"

        # fingerprinted ones from manifest
        manifest.keys.select { |k| k.start_with?("panda-core-") && k.end_with?(".css") }.each do |fname|
          res, data = http_ok?("/panda-core-assets/#{fname}", server_port)
          abort("❌ Missing fingerprinted CSS #{fname}") unless res == :ok
          abort("❌ Fingerprinted CSS #{fname} is empty") if data.strip.empty?
          puts "   ✓ #{fname}"
        end

        # ---------------------------------------------------------------
        # Cleanup server
        # ---------------------------------------------------------------
        Thread.kill(server_thread)

        puts "✅ [Panda Core] Dummy asset verification PASSED (HTTP-level checks)"
      end

      # =========================================================
      # INTERNAL UTILITIES
      # =========================================================

      def find_dummy_root
        root = Rails.root

        return root if root.basename.to_s == "dummy"

        candidate = root.join("spec/dummy")
        return candidate if candidate.exist?

        abort("❌ Cannot find dummy root — expected #{candidate}")
      end
    end
  end
end
