module Panda
  module Core
    class Engine < ::Rails::Engine
      initializer "panda_core.omniauth" do |app|
        require_relative "../oauth_providers"
        Panda::Core::OAuthProviders.setup

        # Global OmniAuth configuration (Rack 3 + Rails 8 safe)
        OmniAuth.config.path_prefix = "#{Panda::Core.config.admin_path}/auth"
        OmniAuth.config.allowed_request_methods = [:post]

        # Build a Rack::Builder instance manually (Rack 3 safe)
        builder = Rack::Builder.new do
          Panda::Core.config.authentication_providers.each do |provider_name, settings|
            provider_opts = settings[:options] || {}

            if settings[:path_name].present?
              provider_opts = provider_opts.merge(name: settings[:path_name])
            end

            case provider_name.to_s
            when "microsoft_graph"
              provider :microsoft_graph, settings[:client_id], settings[:client_secret], provider_opts
            when "google_oauth2"
              provider :google_oauth2, settings[:client_id], settings[:client_secret], provider_opts
            when "github"
              provider :github, settings[:client_id], settings[:client_secret], provider_opts
            when "developer"
              provider :developer if Rails.env.development?
            end
          end
        end

        # Insert the built middleware safely in Rails 8
        safe_insert_before app, ActionDispatch::Executor, builder
      end
    end
  end
end
