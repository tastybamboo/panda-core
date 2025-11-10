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

require "view_component"

module Panda
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Core

      config.eager_load_namespaces << Panda::Core::Engine

      # Add engine's app directories to autoload paths
      # Note: Only add the root directories, not nested subdirectories
      # Zeitwerk will automatically discover nested modules from these roots
      config.autoload_paths += Dir[root.join("app", "models")]
      config.autoload_paths += Dir[root.join("app", "controllers")]
      config.autoload_paths += Dir[root.join("app", "builders")]
      config.autoload_paths += Dir[root.join("app", "components")]
      config.autoload_paths += Dir[root.join("app", "services")]

      # Make files in public available to the main app (e.g. /panda-core-assets/panda-logo.png)
      config.middleware.use Rack::Static,
        urls: ["/panda-core-assets"],
        root: Panda::Core::Engine.root.join("public"),
        header_rules: [
          # Disable caching in development for instant CSS updates
          [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000"}]
        ]

      # Make JavaScript files available for importmap
      # Serve from app/javascript with proper MIME types
      config.middleware.use Rack::Static,
        urls: ["/panda", "/panda/core"],
        root: Panda::Core::Engine.root.join("app/javascript"),
        header_rules: [
          [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000",
                  "Content-Type" => "text/javascript; charset=utf-8"}]
        ]

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: "spec/factories"
      end

      initializer "panda_core.append_migrations" do |app|
        unless app.root.to_s.match?(root.to_s)
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end

      initializer "panda_core.config" do |app|
        # Configuration is already initialized with defaults in Configuration class
      end

      # Add importmap paths from the engine
      initializer "panda_core.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          # Create a new array if frozen
          app.config.importmap.paths = app.config.importmap.paths.dup if app.config.importmap.paths.frozen?

          # Add our paths
          app.config.importmap.paths << root.join("config/importmap.rb")

          # Handle cache sweepers similarly
          if app.config.importmap.cache_sweepers.frozen?
            app.config.importmap.cache_sweepers = app.config.importmap.cache_sweepers.dup
          end
          app.config.importmap.cache_sweepers << root.join("app/javascript")
        end
      end

      initializer "panda_core.omniauth" do |app|
        # Mount OmniAuth at configurable admin path
        app.middleware.use OmniAuth::Builder do
          # Configure OmniAuth to use the configured admin path
          configure do |config|
            config.path_prefix = "#{Panda::Core.config.admin_path}/auth"
            # POST-only for CSRF protection (CVE-2015-9284)
            # All login forms use POST via form_tag method: "post"
            config.allowed_request_methods = [:post]
          end

          Panda::Core.config.authentication_providers.each do |provider_name, settings|
            # Build provider options, allowing custom path name override
            provider_options = settings[:options] || {}

            # If path_name is specified, use it to override the default strategy name in URLs
            if settings[:path_name].present?
              provider_options = provider_options.merge(name: settings[:path_name])
            end

            case provider_name.to_s
            when "microsoft_graph"
              provider :microsoft_graph, settings[:client_id], settings[:client_secret], provider_options
            when "google_oauth2"
              provider :google_oauth2, settings[:client_id], settings[:client_secret], provider_options
            when "github"
              provider :github, settings[:client_id], settings[:client_secret], provider_options
            when "developer"
              provider :developer if Rails.env.development?
            end
          end
        end
      end

      # Load Phlex base component after Rails application is initialized
      # This ensures Rails.application.routes is available
      initializer "panda_core.phlex_base", after: :load_config_initializers do
        require "phlex"
        require "phlex-rails"
        require "literal"
        require "tailwind_merge"

        # Load the base component
        require root.join("app/components/panda/core/base")
      end

      # Set up ViewComponent and Lookbook previews
      initializer "panda_core.view_component" do |app|
        app.config.view_component.preview_paths ||= []
        app.config.view_component.preview_paths << root.join("spec/components/previews")

        # Add preview directories to autoload paths in development
        if Rails.env.development?
          # Handle frozen autoload_paths array
          if app.config.autoload_paths.frozen?
            app.config.autoload_paths = app.config.autoload_paths.dup
          end
          app.config.autoload_paths << root.join("spec/components/previews")
        end
      end

      # Create AdminController alias after controllers are loaded
      # This allows other gems to inherit from Panda::Core::AdminController
      initializer "panda_core.admin_controller_alias", after: :load_config_initializers do
        ActiveSupport.on_load(:action_controller_base) do
          Panda::Core.const_set(:AdminController, Panda::Core::Admin::BaseController) unless Panda::Core.const_defined?(:AdminController)
        end
      end
    end
  end
end
