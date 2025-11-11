# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # OmniAuth configuration
      module OmniauthConfig
        extend ActiveSupport::Concern

        included do
          initializer "panda_core.omniauth" do |app|
            # Load OAuth provider gems
            require_relative "../oauth_providers"
            Panda::Core::OAuthProviders.setup

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
        end
      end
    end
  end
end
