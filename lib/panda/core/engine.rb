require "rubygems"

require "rails/engine"
require "omniauth"
require "omniauth/rails_csrf_protection"
require "view_component"

module Panda
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Core

      config.eager_load_namespaces << Panda::Core::Engine

      # Add engine's app directories to autoload paths
      config.autoload_paths += Dir[root.join("app", "models")]
      config.autoload_paths += Dir[root.join("app", "controllers")]
      config.autoload_paths += Dir[root.join("app", "builders")]
      config.autoload_paths += Dir[root.join("app", "components")]

      # Make files in public available to the main app (e.g. /panda-core-assets/panda-logo.png)
      config.app_middleware.use(
        Rack::Static,
        urls: ["/panda-core-assets"],
        root: Panda::Core::Engine.root.join("public"),
        header_rules: [
          # Disable caching in development for instant CSS updates
          [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000"}]
        ]
      )

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
