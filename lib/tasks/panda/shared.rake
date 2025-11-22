# frozen_string_literal: true

namespace :panda do
  desc "Show all registered modules"
  task registered_modules: :environment do
    Panda::Core::ModuleRegistry.modules(&:map).each do |registered_module, module_attrs|
      puts registered_modules
    end
  end

  desc "Compile the Panda CSS"
  task compile_css: :environment do
    Rails.logger = Logger.new($stdout) if Rails.env.development? || Rails.env.test?

    core_gemspec = Gem::Specification.find_by_name("panda-core")
    output_dir = "#{core_gemspec.full_gem_path}/public/panda-core-assets"

    puts "\n" + ("=" * 80)
    puts "Panda CSS Compilation"
    puts "=" * 80

    registered_modules = Panda::Core::ModuleRegistry.modules(&:map)

    puts "\n📦 Found #{registered_modules.length} registered Panda module(s):"
    registered_modules.each do |gem_name, _info|
      puts "   • #{gem_name}"
    end

    if registered_modules.length == 1
      puts "\n⚠️  Warning: Only compiling CSS for panda-core (no other modules loaded)"
    end

    puts "\n🎨 Output: #{output_dir}/panda-core.css"
    puts ""

    # Generate temporary input CSS with dynamic @source directives
    base_css_path = "#{core_gemspec.full_gem_path}/app/assets/tailwind/application.css"
    temp_css_path = "#{core_gemspec.full_gem_path}/tmp/tailwind-dynamic.css"

    # Ensure tmp directory exists
    FileUtils.mkdir_p(File.dirname(temp_css_path))

    # Read base CSS content
    base_css_content = File.read(base_css_path)

    # Build @source directives for all registered modules
    source_directives = []
    content_paths_count = 0

    registered_modules.each do |gem_name, info|
      gem_path = begin
        gem_spec = Gem::Specification.find_by_name(gem_name)
        gem_spec.full_gem_path
      rescue Gem::LoadError
        Rails.logger.error { "Gem '#{gem_name}' not installed; can't compile panda-core CSS for it" }
        next
      end

      info[:paths].each do |asset_type, path|
        full_path = "#{gem_path}/#{path}"
        puts "   📁 #{asset_type}: #{full_path}"
        source_directives << "@source \"#{full_path}\";"
        content_paths_count += 1
      end
    end

    puts "📂 Scanning #{content_paths_count} content path(s) for Tailwind classes..."
    puts ""

    # Create temporary CSS file with @source directives inserted after @import
    temp_css_content = base_css_content.sub(
      /@import\s+['"]tailwindcss['"];/,
      "@import 'tailwindcss';\n\n/* Dynamic source paths from ModuleRegistry */\n#{source_directives.join("\n")}\n"
    )

    File.write(temp_css_path, temp_css_content)

    command = ["bundle exec tailwindcss",
      "-i #{temp_css_path}",
      "-o #{output_dir}/panda-core.css"]

    command << "--minify"
    # command << "--verbose"  # Enable for debugging

    system(command.join(" "))

    # Clean up temporary file
    File.delete(temp_css_path) if File.exist?(temp_css_path)

    puts "\n" + ("=" * 80)
    if File.exist?("#{output_dir}/panda-core.css")
      filesize = File.size("#{output_dir}/panda-core.css").to_fs(:human_size)
      puts "✅ CSS compilation successful!"
      puts ""
      puts "   Main file:      #{output_dir}/panda-core.css (#{filesize})"

      # Create versioned CSS file
      versioned_css_file = "#{output_dir}/panda-core-#{core_gemspec.version}.css"
      File.copy_stream("#{output_dir}/panda-core.css", versioned_css_file)
      if File.exist?(versioned_css_file)
        puts "   Versioned copy: #{versioned_css_file}"
      end
    else
      puts "❌ CSS compilation failed!"
    end
    puts "=" * 80
    puts ""
  end
end
