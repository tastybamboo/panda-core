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
            # Register OmniAuth middleware during configuration phase
            # Rails 8.1.2+ freezes the middleware stack before initializers run
            config.before_initialize do |app|
              require_relative "../oauth_providers"
              Panda::Core::OAuthProviders.setup
            end

            initializer "panda_core.omniauth_providers" do |app|
              load_yaml_provider_overrides!

              # Configure OmniAuth globals AFTER all initializers have run
              # This ensures Panda::Core.config.admin_path has been set by the app
              app.config.after_initialize do
                configure_omniauth_globals
              end
            end
          end

          # Add OmniAuth middleware during engine configuration
          # This runs before the middleware stack is frozen
          config.app_middleware.use OmniAuth::Builder do
            Panda::Core.config.authentication_providers.each do |name, settings|
              symbol = PROVIDER_REGISTRY[name.to_s]
              next unless symbol
              next if symbol == :developer && !Rails.env.development?

              has_credentials = settings[:client_id].present? && settings[:client_secret].present?
              next if symbol != :developer && !has_credentials

              options = (settings[:options] || {}).dup
              options[:name] = settings[:path_name] if settings[:path_name].present?

              if settings[:client_id] && settings[:client_secret]
                provider symbol, settings[:client_id], settings[:client_secret], options
              else
                provider symbol, options
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

      end
    end
  end
end
