require "rubygems"
require "stringio"

require "rails/engine"
require "omniauth"

# Silence ActiveSupport::Configurable deprecation from omniauth-rails_csrf_protection
# This gem uses the deprecated module but hasn't been updated yet
# Issue: https://github.com/cookpad/omniauth-rails_csrf_protection/issues/23
# This can be removed once the gem is updated or Rails 8.2 is released
#
# We suppress the warning by temporarily redirecting stderr since
# ActiveSupport::Deprecation.silence was removed in Rails 8.1
original_stderr = $stderr
$stderr = StringIO.new
begin
  require "omniauth/rails_csrf_protection"
ensure
  $stderr = original_stderr
end

# Load shared configuration modules
require_relative "shared/inflections_config"
require_relative "shared/generator_config"

# Load engine configuration modules
require_relative "engine/test_config"
require_relative "engine/autoload_config"
require_relative "engine/middleware_config"
require_relative "engine/importmap_config"
require_relative "engine/omniauth_config"
require_relative "engine/phlex_config"
require_relative "engine/admin_controller_config"

# Load module registry
require_relative "module_registry"

module Panda
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Core

      # Include shared configuration modules
      include Shared::InflectionsConfig
      include Shared::GeneratorConfig

      # Include engine-specific configuration modules
      include TestConfig
      include AutoloadConfig
      include MiddlewareConfig
      include ImportmapConfig
      include OmniauthConfig
      include PhlexConfig
      include AdminControllerConfig

      initializer "panda_core.config" do |app|
        # Configuration is already initialized with defaults in Configuration class
      end

      # Static asset middleware for serving public files and JavaScript modules
      initializer "panda.core.static_assets", before: :build_middleware_stack do |app|
        # Make files in public available to the main app (e.g. /panda-core-assets/panda-logo.png)
        app.config.middleware.use Rack::Static,
          urls: ["/panda-core-assets"],
          root: Panda::Core::Engine.root.join("public"),
          header_rules: [
            # Disable caching in development for instant CSS updates
            [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000"}]
          ]

        # JavaScript files are copied to public/panda-core-assets/js/ and served via the panda-core-assets middleware above
        # No additional middleware needed - the first Rack::Static handles both CSS and JS
      end

      # Auto-compile CSS for test/development environments
      initializer "panda_core.auto_compile_assets", after: :load_config_initializers do |app|
        # Only auto-compile in test or when explicitly requested
        next unless Rails.env.test? || ENV["PANDA_CORE_AUTO_COMPILE"] == "true"

        # Use timestamp for cache busting in dev/test
        timestamp = Time.now.to_i
        assets_dir = Panda::Core::Engine.root.join("public", "panda-core-assets")
        timestamped_css = assets_dir.join("panda-core-#{timestamp}.css")

        # Check if any compiled CSS exists (timestamp-based)
        existing_css = Dir[assets_dir.join("panda-core-*.css")].reject { |f| File.symlink?(f) }

        if existing_css.empty?
          warn "🐼 [Panda Core] Auto-compiling CSS for test environment..."

          # Compile CSS with timestamp
          require "open3"
          require "fileutils"

          FileUtils.mkdir_p(assets_dir)

          # Get content paths from ModuleRegistry
          content_paths = Panda::Core::ModuleRegistry.tailwind_content_paths
          content_flags = content_paths.map { |path| "--content '#{path}'" }.join(" ")

          # Compile directly to timestamped file with all registered module content
          input_file = Panda::Core::Engine.root.join("app/assets/tailwind/application.css")
          cmd = "bundle exec tailwindcss -i #{input_file} -o #{timestamped_css} #{content_flags} --minify"

          _, stderr, status = Open3.capture3(cmd)

          if status.success?
            # Create unversioned symlink for fallback
            symlink = assets_dir.join("panda-core.css")
            FileUtils.rm_f(symlink) if File.exist?(symlink)
            FileUtils.ln_sf(File.basename(timestamped_css), symlink)

            warn "🐼 [Panda Core] CSS compilation successful (#{timestamped_css.size} bytes)"
          else
            warn "🐼 [Panda Core] CSS compilation failed: #{stderr}"
          end
        end
      end
    end
  end
end
