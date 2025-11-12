# frozen_string_literal: true

#
# Panda Core Asset Tasks
#
# This file contains BOTH:
#   1. Engine-level CSS compilation (existing functionality)
#   2. Dummy-app asset preparation for system tests (new)
#
# These tasks are used by:
#  - engine developers running local dev
#  - panda-cms CI preparing dummy app
#  - system specs that depend on Propshaft + Importmap + Cuprite
#

namespace :panda do
  namespace :core do
    namespace :assets do
      # --------------------------------------------------------------------------
      # 🐼 1. EXISTING TASKS — ENGINE CSS COMPILATION
      # --------------------------------------------------------------------------

      desc "Compile Panda Core assets for development (overwrites panda-core.css)"
      task :compile do
        puts "🐼 Compiling Panda Core CSS assets (development mode)..."

        output_dir = panda_engine_root.join("public", "panda-core-assets")
        FileUtils.mkdir_p(output_dir)

        compile_css_development(output_dir)

        puts "🎉 Asset compilation complete!"
        puts "📁 Output directory: #{output_dir}"
        puts ""
      end

      desc "Compile and version Panda Core CSS assets for release"
      task :release do
        puts "🐼 Compiling Panda Core CSS assets for release..."

        require_relative "../../panda/core/version"
        version = Panda::Core::VERSION

        output_dir = panda_engine_root.join("public", "panda-core-assets")
        FileUtils.mkdir_p(output_dir)

        compile_css_release(output_dir, version)

        puts "🎉 Release asset compilation complete!"
        puts "📁 Output directory: #{output_dir}"
        puts "📦 Versioned: panda-core-#{version}.css"
      end

      # --------------------------------------------------------------------------
      # 🧩 INTERNAL HELPERS (CSS)
      # --------------------------------------------------------------------------

      def panda_engine_root
        Panda::Core::Engine.root
      end

      def compile_css_development(output_dir)
        engine_root = panda_engine_root
        input_file = engine_root.join("app/assets/tailwind/application.css")
        output_file = output_dir.join("panda-core.css")

        content_paths = Panda::Core::ModuleRegistry.tailwind_content_paths
        content_flags = content_paths.map { |p| "--content '#{p}'" }.join(" ")

        cmd = "bundle exec tailwindcss -i #{input_file} -o #{output_file} #{content_flags} --minify"

        unless system(cmd)
          abort("❌ CSS compilation failed")
        end

        puts "✅ CSS compiled: #{output_file} (#{File.size(output_file)} bytes)"
      end

      def compile_css_release(output_dir, version)
        engine_root = panda_engine_root
        input_file = engine_root.join("app/assets/tailwind/application.css")
        versioned_file = output_dir.join("panda-core-#{version}.css")

        content_paths = Panda::Core::ModuleRegistry.tailwind_content_paths
        content_flags = content_paths.map { |p| "--content '#{p}'" }.join(" ")

        cmd = "bundle exec tailwindcss -i #{input_file} -o #{versioned_file} #{content_flags} --minify"

        unless system(cmd)
          abort("❌ CSS compilation failed")
        end

        symlink = output_dir.join("panda-core.css")
        FileUtils.rm_f(symlink)
        FileUtils.ln_sf(File.basename(versioned_file), symlink)

        puts "✅ Release CSS compiled + symlink generated"
      end

      # --------------------------------------------------------------------------
      # 🚂 2. NEW TASKS — DUMMY APP ASSET PREPARATION (FOR CI + SYSTEM TESTS)
      # --------------------------------------------------------------------------

      desc "Compile Panda Core + host app assets into spec/dummy/public/assets (CI)"
      task compile_dummy: :environment do
        dummy_root = find_dummy_root
        assets_root = dummy_root.join("public/assets")

        puts "🚧 Compiling assets into dummy app:"
        puts "👉 #{assets_root}"

        FileUtils.mkdir_p(assets_root)

        Dir.chdir(dummy_root) do
          # Runs the engine's asset compile pipeline in the dummy app context
          unless system("bundle exec rake app:panda:core:assets:compile")
            abort("❌ Failed to compile Panda Core assets in dummy app")
          end
        end

        puts "✅ Dummy assets compiled"
      end

      desc "Generate importmap.json for Rails 8 dummy app"
      task generate_dummy_importmap: :environment do
        dummy_root = find_dummy_root
        importmap_out = dummy_root.join("public/assets/importmap.json")

        puts "🗺️ Generating importmap.json..."
        FileUtils.mkdir_p(importmap_out.dirname)

        Dir.chdir(dummy_root) do
          map = Rails.application.importmap
          File.write(importmap_out, JSON.pretty_generate(map.to_json))
        end

        puts "✅ importmap.json written to #{importmap_out}"
      end

      desc "Verify dummy app asset readiness (fail-fast for CI)"
      task verify_dummy: :environment do
        dummy_root = find_dummy_root
        assets_root = dummy_root.join("public/assets")
        manifest = assets_root.join(".manifest.json")
        importmap = assets_root.join("importmap.json")

        abort("❌ Missing directory: #{assets_root}") unless Dir.exist?(assets_root)
        abort("❌ Missing #{manifest}") unless File.exist?(manifest)
        abort("❌ Missing #{importmap}") unless File.exist?(importmap)

        begin
          parsed = JSON.parse(File.read(manifest))
          abort("❌ Empty manifest!") if parsed.empty?
        rescue
          abort("❌ Invalid .manifest.json")
        end

        puts "✅ Dummy assets verified"
      end

      # --------------------------------------------------------------------------
      # 🧩 INTERNAL HELPERS (DUMMY APP)
      # --------------------------------------------------------------------------

      def find_dummy_root
        root = Rails.root
        return root if root.basename.to_s == "dummy"

        # For engines, Rails.root will be e.g. panda-cms/
        # In CI we want panda-cms/spec/dummy/
        possible = root.join("spec/dummy")
        return possible if possible.exist?

        abort("❌ Cannot find dummy root at #{possible}")
      end
    end
  end
end
