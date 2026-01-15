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

        class_methods do
          # Load YAML provider overrides during engine definition (before middleware setup)
          def load_yaml_provider_overrides_early!
            path = Panda::Core::Engine.root.join("config/providers.yml")
            return unless File.exist?(path)

            yaml = YAML.load_file(path) || {}
            (yaml["providers"] || {}).each do |name, settings|
              Panda::Core.config.authentication_providers[name.to_s] ||= {}
              Panda::Core.config.authentication_providers[name.to_s].deep_merge!(settings)
            end
          end

          # Configure OmniAuth globals
          def configure_omniauth_globals
            OmniAuth.configure do |c|
              c.allowed_request_methods = [:post]
              c.path_prefix = "#{Panda::Core.config.admin_path}/auth"
            end
          end
        end

        # Instance method for loading YAML provider overrides (for testing)
        # @deprecated Use class method load_yaml_provider_overrides_early! instead
        def load_yaml_provider_overrides!
          path = Panda::Core::Engine.root.join("config/providers.yml")
          return unless File.exist?(path)

          yaml = YAML.load_file(path) || {}
          (yaml["providers"] || {}).each do |name, settings|
            Panda::Core.config.authentication_providers[name.to_s] ||= {}
            Panda::Core.config.authentication_providers[name.to_s].deep_merge!(settings)
          end
        end

        # Configure a single provider on the OmniAuth builder
        # @param builder [OmniAuth::Builder] the OmniAuth builder instance
        # @param name [String] the provider name (may be an alias)
        # @param settings [Hash] provider configuration
        def configure_provider(builder, name, settings)
          symbol = PROVIDER_REGISTRY[name.to_s]

          unless symbol
            Rails.logger.warn("[panda-core] Unknown OmniAuth provider: #{name.inspect}") if defined?(Rails.logger)
            return
          end

          return if symbol == :developer && !Rails.env.development?

          # Skip providers without credentials (except developer which doesn't need them)
          has_credentials = settings[:client_id].present? && settings[:client_secret].present?
          if symbol != :developer && !has_credentials
            Rails.logger.info("[panda-core] Skipping OmniAuth provider #{name.inspect}: missing client_id or client_secret") if defined?(Rails.logger)
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

        included do
          # Only run Rails Engine-specific code when included into an actual Engine
          # This prevents errors when the module is included into test dummy classes
          next unless self < ::Rails::Engine

          # Load YAML overrides early during engine definition so they're available
          # when the OmniAuth middleware block is evaluated
          load_yaml_provider_overrides_early!

          if respond_to?(:initializer)
            # Set up OAuth providers
            config.before_initialize do |app|
              require_relative "../oauth_providers"
              Panda::Core::OAuthProviders.setup
            end

            # Configure OmniAuth globals AFTER all initializers have run
            # This ensures Panda::Core.config.admin_path has been set by the app
            initializer "panda_core.omniauth_globals" do |app|
              app.config.after_initialize do
                Panda::Core::Engine.configure_omniauth_globals
              end
            end
          end

          # Add OmniAuth middleware during engine configuration
          # Rails 8.1.2+ freezes the middleware stack before initializers run
          config.app_middleware.use OmniAuth::Builder do
            # Capture the builder instance for provider configuration
            builder = self
            Panda::Core.config.authentication_providers.each do |name, settings|
              symbol = PROVIDER_REGISTRY[name.to_s]

              unless symbol
                Rails.logger.warn("[panda-core] Unknown OmniAuth provider: #{name.inspect}") if defined?(Rails.logger)
                next
              end

              next if symbol == :developer && !Rails.env.development?

              # Skip providers without credentials (except developer which doesn't need them)
              has_credentials = settings[:client_id].present? && settings[:client_secret].present?
              if symbol != :developer && !has_credentials
                Rails.logger.info("[panda-core] Skipping OmniAuth provider #{name.inspect}: missing client_id or client_secret") if defined?(Rails.logger)
                next
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
  end
end
