# frozen_string_literal: true

require "active_support/concern"

module Panda
  module Core
    module Engine
      module OmniauthConfig
        extend ActiveSupport::Concern

        PROVIDER_REGISTRY = {
          # Microsoft
          "microsoft" => :microsoft_graph,
          "microsoft_graph" => :microsoft_graph,

          # Google
          "google" => :google_oauth2,
          "google_oauth2" => :google_oauth2,
          "gmail" => :google_oauth2,

          # GitHub
          "github" => :github,
          "gh" => :github,

          # Developer
          "developer" => :developer
        }.freeze

        included do
          # Main initializer
          initializer "panda_core.omniauth" do |app|
            require_relative "../oauth_providers"
            Panda::Core::OAuthProviders.setup

            load_yaml_provider_overrides!

            configure_omniauth_globals
            mount_omniauth_middleware(app)
          end
        end

        private

        # ---------------------------------------------------------------------
        # 1. Load providers from YAML (optional)
        # ---------------------------------------------------------------------
        def load_yaml_provider_overrides!
          yaml_path = Panda::Core::Engine.root.join("config/providers.yml")
          return unless File.exist?(yaml_path)

          yaml = YAML.load_file(yaml_path) || {}
          overrides = yaml["providers"] || {}

          overrides.each do |name, settings|
            Panda::Core.config.authentication_providers[name.to_s] ||= {}
            Panda::Core.config.authentication_providers[name.to_s].deep_merge!(settings)
          end
        end

        # ---------------------------------------------------------------------
        # 2. Global OmniAuth configuration
        # ---------------------------------------------------------------------
        def configure_omniauth_globals
          OmniAuth.configure do |c|
            c.allowed_request_methods = [:post]
            c.path_prefix = "#{Panda::Core.config.admin_path}/auth"
            # c.silence_ready = true
            # c.silence_warnings = true
          end
        end

        # ---------------------------------------------------------------------
        # 3. Insert OmniAuth middleware safely
        # ---------------------------------------------------------------------
        def mount_omniauth_middleware(app)
          Panda::Core::Middleware.use(app, OmniAuth::Builder) do
            Panda::Core.config.authentication_providers.each do |name, settings|
              configure_provider(self, name, settings)
            end
          end
        end

        # ---------------------------------------------------------------------
        # 4. Provider resolution + configuration
        # ---------------------------------------------------------------------
        def configure_provider(builder, name, settings)
          symbol = PROVIDER_REGISTRY[name.to_s]

          unless symbol
            Rails.logger.warn("[panda-core] Unknown OmniAuth provider: #{name.inspect}")
            return
          end

          if symbol == :developer && !Rails.env.development?
            return
          end

          options = (settings[:options] || {}).dup
          options[:name] = settings[:path_name] if settings[:path_name].present?

          if settings[:client_id] && settings[:client_secret]
            builder.provider(symbol, settings[:client_id], settings[:client_secret], options)
          else
            builder.provider(symbol, options)
          end
        end
      end
    end
  end
end
