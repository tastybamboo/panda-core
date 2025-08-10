# frozen_string_literal: true

require "fileutils"
require "digest"
require "json"

namespace :panda do
  namespace :core do
    namespace :assets do
      desc "Compile Panda Core assets for distribution"
      task :compile do
        puts "🐼 Compiling Panda Core assets..."
        puts "Rails.root: #{Rails.root}"
        puts "Working directory: #{Dir.pwd}"

        # Create output directory
        output_dir = Rails.root.join("tmp", "panda_core_assets")
        FileUtils.mkdir_p(output_dir)

        version = Panda::Core::VERSION
        puts "Version: #{version}"
        puts "Output directory: #{output_dir}"

        # Compile JavaScript bundle
        js_bundle = compile_javascript_bundle(version)
        js_file = output_dir.join("panda-core-#{version}.js")
        File.write(js_file, js_bundle)
        puts "✅ JavaScript compiled: #{js_file} (#{File.size(js_file)} bytes)"

        # Compile CSS bundle (for core UI components)
        css_bundle = compile_css_bundle(version)
        if css_bundle && !css_bundle.strip.empty?
          css_file = output_dir.join("panda-core-#{version}.css")
          File.write(css_file, css_bundle)
          puts "✅ CSS compiled: #{css_file} (#{File.size(css_file)} bytes)"
        end

        # Create manifest file
        manifest = create_asset_manifest(version)
        manifest_file = output_dir.join("manifest.json")
        File.write(manifest_file, JSON.pretty_generate(manifest))
        puts "✅ Manifest created: #{manifest_file}"

        # Copy assets to public directory for testing
        test_asset_dir = Rails.root.join("public", "panda-core-assets")
        FileUtils.mkdir_p(test_asset_dir)

        js_file_name = "panda-core-#{version}.js"
        css_file_name = "panda-core-#{version}.css"

        # Copy JavaScript file
        if File.exist?(output_dir.join(js_file_name))
          FileUtils.cp(output_dir.join(js_file_name), test_asset_dir.join(js_file_name))
          puts "✅ Copied JavaScript to test location: #{test_asset_dir.join(js_file_name)}"
        end

        # Copy CSS file
        if File.exist?(output_dir.join(css_file_name))
          FileUtils.cp(output_dir.join(css_file_name), test_asset_dir.join(css_file_name))
          puts "✅ Copied CSS to test location: #{test_asset_dir.join(css_file_name)}"
        end

        # Copy manifest
        if File.exist?(output_dir.join("manifest.json"))
          FileUtils.cp(output_dir.join("manifest.json"), test_asset_dir.join("manifest.json"))
          puts "✅ Copied manifest to test location: #{test_asset_dir.join("manifest.json")}"
        end

        puts "🎉 Asset compilation complete!"
        puts "📁 Output directory: #{output_dir}"
        puts "📁 Test assets directory: #{test_asset_dir}"
      end
    end
  end
end

private

def compile_javascript_bundle(version)
  puts "Creating Panda Core JavaScript bundle..."

  bundle = []
  bundle << "// Panda Core JavaScript Bundle v#{version}"
  bundle << "// Compiled: #{Time.now.utc.iso8601}"
  bundle << "// Core UI components and authentication"
  bundle << ""

  # Add Stimulus setup for core
  bundle << create_stimulus_setup

  # Add core controllers (theme form controller, etc.)
  bundle << compile_core_controllers

  # Add initialization
  bundle << create_core_init(version)

  puts "✅ Created JavaScript bundle (#{bundle.join("\n").length} chars)"
  bundle.join("\n")
end

def compile_css_bundle(version)
  puts "Creating Panda Core CSS bundle..."

  bundle = []
  bundle << "/* Panda Core CSS Bundle v#{version} */"
  bundle << "/* Compiled: #{Time.now.utc.iso8601} */"
  bundle << ""

  # Add core UI component styles
  bundle << "/* Core UI Components */"
  bundle << ".panda-core-admin {"
  bundle << "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;"
  bundle << "}"
  bundle << ""
  bundle << ".panda-core-button {"
  bundle << "  display: inline-flex;"
  bundle << "  align-items: center;"
  bundle << "  padding: 0.5rem 1rem;"
  bundle << "  border-radius: 0.375rem;"
  bundle << "  font-weight: 500;"
  bundle << "}"
  bundle << ""
  bundle << ".panda-core-container {"
  bundle << "  padding: 1.5rem;"
  bundle << "  background: white;"
  bundle << "  border-radius: 0.5rem;"
  bundle << "}"
  bundle << ""

  puts "✅ Created CSS bundle (#{bundle.join("\n").length} chars)"
  bundle.join("\n")
end

def create_stimulus_setup
  <<~JS
    // Stimulus Setup for Panda Core
    (function() {
      if (typeof window.Stimulus === 'undefined') {
        console.warn('Stimulus not found, initializing...');
        // Minimal Stimulus polyfill for testing
        window.Stimulus = {
          register: function(name, controller) {
            console.log('Registered controller:', name);
          }
        };
      }
      window.pandaCoreStimulus = window.Stimulus;
    })();
  JS
end

def compile_core_controllers
  puts "Compiling Core controllers..."

  bundle = []
  bundle << "// Core Controllers"

  # Find controller files in the engine
  engine_root = File.expand_path("../../..", __FILE__)
  controller_dir = File.join(engine_root, "app", "javascript", "panda", "core", "controllers")

  if File.directory?(controller_dir)
    Dir.glob(File.join(controller_dir, "*.js")).each do |file|
      next if File.basename(file) == "index.js"

      controller_name = File.basename(file, ".js").tr("_", "-")
      puts "  Adding controller: #{controller_name}"

      content = File.read(file)
      bundle << "// Controller: #{controller_name}"
      bundle << content
      bundle << ""
    end
  else
    puts "  No controller directory found at: #{controller_dir}"
  end

  bundle.join("\n")
end

def create_core_init(version)
  <<~JS
    // Panda Core Initialization
    (function() {
      window.pandaCoreLoaded = true;
      window.pandaCoreVersion = '#{version}';
      console.log('Panda Core v#{version} loaded');
      
      // Initialize theme controller if present
      if (window.Stimulus && window.Stimulus.register) {
        // Controllers are auto-registered above
      }
    })();
  JS
end

def create_asset_manifest(version)
  output_dir = Rails.root.join("tmp", "panda_core_assets")

  files = Dir.glob(output_dir.join("*")).reject { |f| File.basename(f) == "manifest.json" }.map do |file|
    {
      filename: File.basename(file),
      size: File.size(file),
      sha256: Digest::SHA256.file(file).hexdigest
    }
  end

  {
    version: version,
    compiled_at: Time.now.utc.iso8601,
    files: files,
    cdn_base_url: "https://github.com/tastybamboo/panda-core/releases/download/v#{version}/",
    integrity: {
      algorithm: "sha256"
    }
  }
end
