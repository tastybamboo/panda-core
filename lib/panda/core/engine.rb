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

      initializer "panda_core.configuration" do |app|
        # Configuration is already initialized with defaults in Configuration class
      end


      initializer "panda_core.omniauth" do |app|
        # Mount OmniAuth at configurable admin path
        app.middleware.use OmniAuth::Builder do
          # Configure OmniAuth to use the configured admin path
          configure do |config|
            config.path_prefix = "#{Panda::Core.configuration.admin_path}/auth"
            # Allow POST requests for request phase (required for CSRF protection)
            config.allowed_request_methods = [:get, :post]
          end

          Panda::Core.configuration.authentication_providers.each do |provider_name, settings|
            case provider_name.to_s
            when "microsoft_graph"
              provider :microsoft_graph, settings[:client_id], settings[:client_secret], settings[:options] || {}
            when "google_oauth2"
              provider :google_oauth2, settings[:client_id], settings[:client_secret], settings[:options] || {}
            when "github"
              provider :github, settings[:client_id], settings[:client_secret], settings[:options] || {}
            when "developer"
              provider :developer if Rails.env.development?
            end
          end
        end
      end
    end
  end
end
