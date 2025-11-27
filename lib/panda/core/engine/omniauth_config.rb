# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      module OmniauthConfig
        extend ActiveSupport::Concern

        included do
          config.middleware.use OmniAuth::Builder do
            # Load provider definitions
            require_relative "../oauth_providers"
            Panda::Core::OAuthProviders.setup

            # Configure path prefix and allowed request methods
            configure do |config|
              config.path_prefix = "#{Panda::Core.config.admin_path}/auth"
              config.allowed_request_methods = [:post] # Mitigate CVE-2015-9284
            end

            # Register OAuth providers
            Panda::Core.config.authentication_providers.each do |provider_name, settings|
              opts = settings[:options] || {}

              # Optional path_name override
              if settings[:path_name].present?
                opts = opts.merge(name: settings[:path_name])
              end

              case provider_name.to_s
              when "microsoft_graph"
                provider :microsoft_graph, settings[:client_id], settings[:client_secret], opts
              when "google_oauth2"
                provider :google_oauth2, settings[:client_id], settings[:client_secret], opts
              when "github"
                provider :github, settings[:client_id], settings[:client_secret], opts
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
