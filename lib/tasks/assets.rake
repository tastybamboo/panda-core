# frozen_string_literal: true

namespace :panda do
  namespace :core do
    namespace :assets do
      desc "Compile Panda Core assets for development (overwrites panda-core.css)"
      task :compile do
        puts "🐼 Compiling Panda Core assets..."

        # Create output directory
        output_dir = Panda::Core::Engine.root.join("public", "panda-core-assets")
        FileUtils.mkdir_p(output_dir)

        # Compile CSS using Tailwind CSS v4
        compile_css_development(output_dir)

        puts "🎉 Asset compilation complete!"
        puts "📁 Output directory: #{output_dir}"
        puts ""
        puts "💡 CSS is served via Rack middleware from Core gem at /panda-core-assets/panda-core.css"
        puts "   No need to copy to CMS or other apps - they load it from Core automatically!"
      end

      desc "Compile and version Panda Core assets for release"
      task :release do
        puts "🐼 Compiling Panda Core assets for release..."

        # Get version
        require_relative "../panda/core/version"
        version = Panda::Core::VERSION
        puts "Version: #{version}"

        # Create output directory
        output_dir = Panda::Core::Engine.root.join("public", "panda-core-assets")
        FileUtils.mkdir_p(output_dir)

        # Compile CSS with versioning
        compile_css_release(output_dir, version)

        puts "🎉 Release asset compilation complete!"
        puts "📁 Output directory: #{output_dir}"
        puts "📦 Versioned: panda-core-#{version}.css"
        puts "🔗 Symlink: panda-core.css -> panda-core-#{version}.css"
      end

      def compile_css_development(output_dir)
        puts "Compiling Tailwind CSS (development mode)..."

        engine_root = Panda::Core::Engine.root
        input_file = engine_root.join("app/assets/tailwind/application.css")
        output_file = output_dir.join("panda-core.css")

        # Get content paths from ModuleRegistry
        content_paths = Panda::Core::ModuleRegistry.tailwind_content_paths
        content_flags = content_paths.map { |path| "--content '#{path}'" }.join(" ")

        # Compile with all registered module content
        cmd = "bundle exec tailwindcss -i #{input_file} -o #{output_file} #{content_flags} --minify"

        if system(cmd)
          puts "✅ CSS compiled: #{output_file} (#{File.size(output_file)} bytes)"
          puts "📦 Included content from: #{Panda::Core::ModuleRegistry.registered_modules.join(", ")}" if Panda::Core::ModuleRegistry.registered_modules.any?
        else
          puts "❌ CSS compilation failed"
          exit 1
        end
      end

      def compile_css_release(output_dir, version)
        puts "Compiling Tailwind CSS (release mode)..."

        engine_root = Panda::Core::Engine.root
        input_file = engine_root.join("app/assets/tailwind/application.css")
        versioned_file = output_dir.join("panda-core-#{version}.css")

        # Get content paths from ModuleRegistry
        content_paths = Panda::Core::ModuleRegistry.tailwind_content_paths
        content_flags = content_paths.map { |path| "--content '#{path}'" }.join(" ")

        # Compile to versioned file with all registered module content
        cmd = "bundle exec tailwindcss -i #{input_file} -o #{versioned_file} #{content_flags} --minify"

        if system(cmd)
          puts "✅ CSS compiled: #{versioned_file} (#{File.size(versioned_file)} bytes)"
          puts "📦 Included content from: #{Panda::Core::ModuleRegistry.registered_modules.join(", ")}" if Panda::Core::ModuleRegistry.registered_modules.any?

          # Create/update unversioned symlink
          symlink = output_dir.join("panda-core.css")
          FileUtils.rm_f(symlink) if File.exist?(symlink)
          FileUtils.ln_sf(File.basename(versioned_file), symlink)
          puts "✅ Created symlink: #{symlink} -> #{File.basename(versioned_file)}"
        else
          puts "❌ CSS compilation failed"
          exit 1
        end
      end
    end
  end
end
