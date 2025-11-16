# frozen_string_literal: true

require "ferrum"
require "capybara/cuprite"

# Shared Cuprite driver configuration for all Panda gems
# This provides standard Cuprite setup with sensible defaults that work across gems
#
# Features:
# - :cuprite driver for standard desktop testing
# - :cuprite_mobile driver for mobile viewport testing
# - JavaScript error reporting enabled by default (js_errors: true)
# - CI-optimized browser options
# - Environment-based configuration (HEADLESS, INSPECTOR, SLOWMO)

module Panda
  module Core
    module Testing
      module CupriteSetup
        # Base Cuprite options shared across all drivers
        def self.base_options
          default_timeout = 2
          default_process_timeout = 2

          {
            window_size: [1440, 1000],
            inspector: ENV["INSPECTOR"].in?(%w[y 1 yes true]),
            headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
            slowmo: ENV["SLOWMO"]&.to_f || 0,
            timeout: ENV["CUPRITE_TIMEOUT"]&.to_i || default_timeout,
            js_errors: true,  # IMPORTANT: Report JavaScript errors as test failures
            ignore_default_browser_options: false,
            process_timeout: ENV["CUPRITE_PROCESS_TIMEOUT"]&.to_i || default_process_timeout,
            wait_for_network_idle: false,  # Don't wait for all network requests
            pending_connection_errors: false,  # Don't fail on pending external connections
            browser_options: {
              "no-sandbox": nil,
              "disable-gpu": nil,
              "disable-dev-shm-usage": nil,
              "disable-background-networking": nil,
              "disable-default-apps": nil,
              "disable-extensions": nil,
              "disable-sync": nil,
              "disable-translate": nil,
              "no-first-run": nil,
              "ignore-certificate-errors": nil,
              "allow-insecure-localhost": nil,
              "enable-features": "NetworkService,NetworkServiceInProcess",
              "disable-blink-features": "AutomationControlled"
            }
          }
        end

        # Additional options for CI environments
        def self.ci_browser_options
          {
            "disable-web-security": nil,
            "allow-file-access-from-files": nil,
            "allow-file-access": nil
          }
        end

        # Configure standard desktop driver
        def self.register_desktop_driver
          options = base_options.dup

          # Add CI-specific options
          if ENV["GITHUB_ACTIONS"] == "true"
            options[:browser_options].merge!(ci_browser_options)

            # Ensure CI uses xvfb to run the browser
            options[:browser_options][:xvfb] = true
          end

          Capybara.register_driver :cuprite do |app|
            Capybara::Cuprite::Driver.new(app, **options)
          end
        end

        # Configure mobile viewport driver
        def self.register_mobile_driver
          options = base_options.dup
          options[:window_size] = [375, 667]  # iPhone SE size

          if ENV["GITHUB_ACTIONS"] == "true"
            options[:browser_options].merge!(ci_browser_options)
          end

          Capybara.register_driver :cuprite_mobile do |app|
            Capybara::Cuprite::Driver.new(app, **options)
          end
        end

        # Register all drivers
        def self.setup!
          register_desktop_driver
          register_mobile_driver

          # Set default drivers
          Capybara.default_driver = :cuprite
          Capybara.javascript_driver = :cuprite
        end
      end
    end
  end
end

# Auto-setup when required
Panda::Core::Testing::CupriteSetup.setup!
