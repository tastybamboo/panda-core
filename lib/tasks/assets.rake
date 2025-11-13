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

        map = Rails.application.importmap.as_json(
          resolver: ActionController::Base.helpers
        )

        importmap_path = dummy_root.join("public/assets/importmap.json")
        FileUtils.mkdir_p(importmap_path.dirname)

        File.write(importmap_path, JSON.pretty_generate(map))

        puts "   ✓ importmap.json written"
      end

      desc "Verify Panda Core dummy assets (Propshaft + Importmap + HTTP checks)"
      task :verify_dummy do
        dummy_root = find_dummy_root
        assets_root = dummy_root.join("public/assets")
        manifest_path = assets_root.join(".manifest.json")
        importmap_path = assets_root.join("importmap.json")
        css_glob = Panda::Core::Engine.root.join("public/panda-core-assets/panda-core*.css")

        puts "\e[36m🔍 [Panda Core] Verifying dummy asset readiness...\e[0m"

        #
        # 1. Directory checks
        #
        abort("\e[31m❌ Missing #{assets_root}\e[0m") unless Dir.exist?(assets_root)

        abort("\e[31m❌ Missing Propshaft manifest: #{manifest_path}\e[0m") unless File.exist?(manifest_path)
        abort("\e[31m❌ Missing importmap.json: #{importmap_path}\e[0m") unless File.exist?(importmap_path)

        #
        # 2. Manifest
        #
        manifest = JSON.parse(File.read(manifest_path))
        if manifest.empty?
          abort("\e[31m❌ Propshaft manifest is empty!\e[0m")
        end

        puts "  \e[32m✓ Manifest loaded (#{manifest.size} entries)\e[0m"

        #
        # 3. Importmap (must be a Hash with imports)
        #
        importmap = JSON.parse(File.read(importmap_path))
        imports = importmap["imports"]

        unless imports.is_a?(Hash)
          abort("\e[31m❌ importmap.json malformed — expected { \"imports\": { ... } }\e[0m")
        end

        puts "  \e[32m✓ Importmap loaded (#{imports.size} imports)\e[0m"

        #
        # 4. Panda Core CSS exists
        #
        css_files = Dir[css_glob.to_s]

        if css_files.empty?
          abort("\e[31m❌ No compiled Panda Core CSS found at #{css_glob}\e[0m")
        end

        puts "  \e[32m✓ Core CSS present (#{css_files.size} file(s))\e[0m"

        #
        # 5. HTTP checks against running Puma server
        #
        require "net/http"
        base = "http://127.0.0.1:#{Capybara.server_port}"

        puts "\n\e[36m🔍 Checking HTTP responses...\e[0m"

        # Helper
        http_ok = lambda do |path|
          uri = URI("#{base}#{path}")
          res = Net::HTTP.get_response(uri)
          res.is_a?(Net::HTTPSuccess)
        rescue => e
          puts "    \e[31mHTTP ERROR #{path}: #{e.message}\e[0m"
          false
        end

        # CSS
        css_files.each do |css|
          logical = "/panda-core-assets/#{File.basename(css)}"
          unless http_ok.call(logical)
            abort("\e[31m❌ CSS not served correctly: #{logical}\e[0m")
          end
          puts "    \e[32m✓ #{logical}\e[0m"
        end

        # Importmap modules
        imports.each do |logical_name, path|
          unless http_ok.call(path)
            abort("\e[31m❌ Importmap module failing: #{logical_name} → #{path}\e[0m")
          end
          puts "    \e[32m✓ #{logical_name} (#{path})\e[0m"
        end

        puts "\n\e[42m\e[30m✔ Panda Core dummy assets VERIFIED\e[0m"
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
