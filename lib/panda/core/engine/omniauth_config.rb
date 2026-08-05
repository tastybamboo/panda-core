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

          # Apple (Sign in with Apple)
          "apple" => :apple,

          # Developer
          "developer" => :developer
        }.freeze

        # Whether a provider has enough credentials to register / show on login.
        # Apple uses a JWT client secret derived from team_id / key_id / pem
        # (no static client_secret).
        def self.credentials_configured?(symbol, settings)
          case symbol.to_sym
          when :developer
            true
          when :apple
            apple_credentials_configured?(settings)
          else
            settings[:client_id].present? && settings[:client_secret].present?
          end
        end

        def self.apple_credentials_configured?(settings)
          settings[:client_id].present? &&
            settings.dig(:options, :team_id).present? &&
            settings.dig(:options, :key_id).present? &&
            settings.dig(:options, :pem).present?
        end

        # Register a provider on an OmniAuth::Builder.
        # Apple's strategy ignores the static secret and signs a JWT from options.
        def self.register_provider(builder, symbol, settings, options)
          case symbol.to_sym
          when :apple
            builder.provider :apple, settings[:client_id], "", options
          when :developer
            builder.provider :developer, options
          else
            builder.provider symbol, settings[:client_id], settings[:client_secret], options
          end
        end

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

              # OmniAuth's built-in AuthenticityTokenProtection uses
              # Rack::Protection's :csrf session key, but Rails stores its
              # CSRF token under :_csrf_token. This session key mismatch
              # causes "Forbidden" errors when submitting the admin login form.
              #
              # Disabling OmniAuth's request_validation_phase is safe because:
              # - Production OAuth providers (Google, GitHub, Microsoft, Apple)
              #   are protected by the OAuth state parameter in the callback phase
              # - The developer provider only runs in development/test
              # - The login form still requires POST (allowed_request_methods)
              c.request_validation_phase = nil
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

          unless OmniauthConfig.credentials_configured?(symbol, settings)
            Rails.logger.info("[panda-core] Skipping OmniAuth provider #{name.inspect}: missing credentials") if defined?(Rails.logger)
            return
          end

          options = (settings[:options] || {}).dup
          options[:name] = settings[:path_name] if settings[:path_name].present?

          OmniauthConfig.register_provider(builder, symbol, settings, options)
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

              unless OmniauthConfig.credentials_configured?(symbol, settings)
                Rails.logger.info("[panda-core] Skipping OmniAuth provider #{name.inspect}: missing credentials") if defined?(Rails.logger)
                next
              end

              options = (settings[:options] || {}).dup
              options[:name] = settings[:path_name] if settings[:path_name].present?

              # Inject a setup lambda that gates providers per-request (e.g. per-tenant)
              # and allows dynamic redirect_uri override for multi-subdomain OAuth flows.
              gate = Panda::Core.config.authentication_provider_gate
              if gate && symbol != :developer
                provider_name = name.to_s
                options[:setup] = ->(env) {
                  unless gate.call(provider_name, env)
                    raise OmniAuth::Error, "Provider not enabled for this workspace"
                  end
                }
              end

              OmniauthConfig.register_provider(builder, symbol, settings, options)
            end
          end
        end
      end
    end
  end
end
