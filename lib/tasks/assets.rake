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

      desc "Verify dummy assets for CI (fail-fast)"
      task verify_dummy: :environment do
        dummy_root = find_dummy_root
        assets = dummy_root.join("public/assets")
        manifest = assets.join(".manifest.json")
        importmap = assets.join("importmap.json")

        abort("❌ Missing #{assets}") unless assets.exist?
        abort("❌ Missing #{manifest}") unless manifest.exist?
        abort("❌ Missing #{importmap}") unless importmap.exist?

        begin
          parsed = JSON.parse(File.read(manifest))
          abort("❌ Empty .manifest.json") if parsed.empty?
        rescue
          abort("❌ Invalid .manifest.json")
        end

        puts "✅ Dummy assets verified"
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
