# frozen_string_literal: true

require "active_support/concern"

module Panda
  module Core
    module Engine
      module OmniauthConfig
        extend ActiveSupport::Concern

        PROVIDER_REGISTRY = {
          "microsoft" => :microsoft_graph,
          "microsoft_graph" => :microsoft_graph,
          "google" => :google_oauth2,
          "google_oauth2" => :google_oauth2,
          "gmail" => :google_oauth2,
          "github" => :github,
          "gh" => :github,
          "developer" => :developer
        }.freeze

        included do
          initializer "panda_core.omniauth" do |app|
            require_relative "../oauth_providers"
            Panda::Core::OAuthProviders.setup

            load_yaml_provider_overrides!
            configure_omniauth_globals

            Panda::Core::Middleware.use(app, OmniAuth::Builder) do |builder|
              Panda::Core.config.authentication_providers.each do |name, settings|
                OmniauthConfig.configure_provider(builder, name, settings)
              end
            end
          end
        end

        # ---------------------------------------------------------
        # Make configure_provider a module function, not instance
        # ---------------------------------------------------------
        class << self
          def configure_provider(builder, name, settings)
            symbol = PROVIDER_REGISTRY[name.to_s]

            unless symbol
              Rails.logger.warn("[panda-core] Unknown OmniAuth provider: #{name.inspect}")
              return
            end

            return if symbol == :developer && !Rails.env.development?

            options = (settings[:options] || {}).dup
            options[:name] = settings[:path_name] if settings[:path_name].present?

            if settings[:client_id] && settings[:client_secret]
              builder.provider(symbol, settings[:client_id], settings[:client_secret], options)
            else
              builder.provider(symbol, options)
            end
          end
        end

        private

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

        def configure_omniauth_globals
          OmniAuth.configure do |c|
            c.allowed_request_methods = [:post]
            c.path_prefix = "#{Panda::Core.config.admin_path}/auth"
          end
        end
      end
    end
  end
end
