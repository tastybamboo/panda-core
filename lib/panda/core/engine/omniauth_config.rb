# frozen_string_literal: true

require "active_support/concern"

module Panda
  module Core
    class Engine < ::Rails::Engine
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
          if respond_to?(:initializer)
            initializer "panda_core.omniauth" do |app|
              require_relative "../oauth_providers"
              Panda::Core::OAuthProviders.setup

              load_yaml_provider_overrides!
              mount_omniauth_middleware(app)

              # Configure OmniAuth globals AFTER all initializers have run
              # This ensures Panda::Core.config.admin_path has been set by the app
              app.config.after_initialize do
                configure_omniauth_globals
              end
            end
          end
        end

        private

        # 1. YAML overrides
        def load_yaml_provider_overrides!
          path = Panda::Core::Engine.root.join("config/providers.yml")
          return unless File.exist?(path)

          yaml = YAML.load_file(path) || {}
          (yaml["providers"] || {}).each do |name, settings|
            Panda::Core.config.authentication_providers[name.to_s] ||= {}
            Panda::Core.config.authentication_providers[name.to_s].deep_merge!(settings)
          end
        end

        # 2. Global settings
        def configure_omniauth_globals
          OmniAuth.configure do |c|
            c.allowed_request_methods = [:post]
            c.path_prefix = "#{Panda::Core.config.admin_path}/auth"
          end
        end

        # 3. Middleware insertion
        def mount_omniauth_middleware(app)
          ctx = self  # Capture the Engine/Concern context

          Panda::Core::Middleware.use(app, OmniAuth::Builder) do
            Panda::Core.config.authentication_providers.each do |name, settings|
              ctx.send(:configure_provider, self, name, settings)
            end
          end
        end

        # 4. Provider builder
        def configure_provider(builder, name, settings)
          symbol = PROVIDER_REGISTRY[name.to_s]

          unless symbol
            Rails.logger.warn("[panda-core] Unknown OmniAuth provider: #{name.inspect}")
            return
          end

          return if symbol == :developer && !Rails.env.development?

          # Skip providers without credentials (except developer which doesn't need them)
          has_credentials = settings[:client_id].present? && settings[:client_secret].present?
          if symbol != :developer && !has_credentials
            Rails.logger.info("[panda-core] Skipping OmniAuth provider #{name.inspect}: missing client_id or client_secret")
            return
          end

          options = (settings[:options] || {}).dup
          options[:name] = settings[:path_name] if settings[:path_name].present?

          if settings[:client_id] && settings[:client_secret]
            builder.provider symbol, settings[:client_id], settings[:client_secret], options
          else
            builder.provider symbol, options
          end
        end
      end
    end
  end
end
