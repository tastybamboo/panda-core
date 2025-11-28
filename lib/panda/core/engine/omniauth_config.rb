# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      module OmniauthConfig
        extend ActiveSupport::Concern

        included do
          initializer "panda_core.omniauth" do |app|
            # Load provider list + configuration defaults
            require_relative "../oauth_providers"
            Panda::Core::OAuthProviders.setup

            # -------------------------------------------------------
            # Global OmniAuth configuration (Rails 8 / Rack 3 safe)
            # -------------------------------------------------------
            OmniAuth.configure do |c|
              c.allowed_request_methods = [:post]
              c.path_prefix = "#{Panda::Core.config.admin_path}/auth"
              # You may add:
              # c.silence_ready = true
              # c.silence_warnings = true
            end

            # -------------------------------------------------------
            # Insert OmniAuth middleware safely
            #   Using your safe helper, we avoid touching frozen stacks
            # -------------------------------------------------------
            Panda::Core::Middleware.use(app, OmniAuth::Builder) do
              Panda::Core.config.authentication_providers.each do |provider_name, settings|
                options = settings[:options] || {}

                # Override path_name (strategy name) if provided
                options = options.merge(name: settings[:path_name]) if settings[:path_name].present?

                case provider_name.to_s
                when "microsoft_graph"
                  provider :microsoft_graph, settings[:client_id], settings[:client_secret], options
                when "google_oauth2"
                  provider :google_oauth2, settings[:client_id], settings[:client_secret], options
                when "github"
                  provider :github, settings[:client_id], settings[:client_secret], options
                when "developer"
                  provider :developer if Rails.env.development?
                else
                  Rails.logger.warn("[panda-core] Unknown OmniAuth provider: #{provider_name.inspect}")
                end
              end
            end
          end
        end
      end
    end
  end
end
