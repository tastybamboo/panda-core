require "ferrum"
require "capybara/cuprite"
require_relative "ferrum_console_logger"
require_relative "browser_path"

module Panda
  module Core
    module Testing
      module CupriteSetup
        @console_logger = nil

        class << self
          attr_accessor :console_logger
        end

        def self.base_options
          ci_default_timeout = 10
          ci_default_process_timeout = 30
          default_timeout = ENV["CI"] ? ci_default_timeout : 5
          default_process_timeout = ENV["CI"] ? ci_default_process_timeout : 10

          cuprite_timeout = ENV["CUPRITE_TIMEOUT"]&.to_i ||
            ENV["FERRUM_TIMEOUT"]&.to_i ||
            default_timeout

          process_timeout_value = ENV["CUPRITE_PROCESS_TIMEOUT"]&.to_i ||
            ENV["FERRUM_PROCESS_TIMEOUT"]&.to_i ||
            default_process_timeout

          puts "[Cuprite Config] timeout = #{cuprite_timeout}, process_timeout = #{process_timeout_value}" if ENV["CI"] || ENV["DEBUG"]
          puts "[Cuprite Config] ENV: CUPRITE_TIMEOUT=#{ENV["CUPRITE_TIMEOUT"].inspect}, CUPRITE_PROCESS_TIMEOUT=#{ENV["CUPRITE_PROCESS_TIMEOUT"].inspect}" if ENV["CI"] || ENV["DEBUG"]

          browser_path = ENV["BROWSER_PATH"] || Panda::Core::Testing::Support::System::BrowserPath.resolve

          {
            browser_path: browser_path,
            window_size: [1440, 1000],
            inspector: ENV["INSPECTOR"].in?(%w[y 1 yes true]),
            headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
            slowmo: ENV["SLOWMO"]&.to_f || 0,
            timeout: cuprite_timeout,
            js_errors: true,
            ignore_default_browser_options: false,
            process_timeout: process_timeout_value,
            wait_for_network_idle: false,
            pending_connection_errors: false,
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
              "disable-blink-features": "AutomationControlled",
              "no-dbus": nil,
              "log-level": ENV["CI"] ? "0" : "3"
            }
          }
        end

        def self.ci_browser_options
          {
            "disable-web-security": nil,
            "allow-file-access-from-files": nil,
            "allow-file-access": nil
          }
        end

        def self.register_desktop_driver
          options = base_options.dup

          if ENV["GITHUB_ACTIONS"] == "true"
            options[:browser_options].merge!(ci_browser_options)
          end

          self.console_logger = Panda::Core::Testing::Support::System::FerrumConsoleLogger.new
          options[:logger] = console_logger

          if ENV["CI"] || ENV["DEBUG"]
            puts "[Cuprite Config] Final driver options:"
            puts "  timeout: #{options[:timeout]}"
            puts "  process_timeout: #{options[:process_timeout]}"
            puts "  headless: #{options[:headless]}"
            puts "  window_size: #{options[:window_size]}"
            puts "  Browser options count: #{options[:browser_options].keys.count}"
          end

          Capybara.register_driver :cuprite do |app|
            if ENV["CI"] || ENV["DEBUG"]
              puts "[Cuprite Driver Instantiation] Creating driver with options:"
              puts "  timeout: #{options[:timeout].inspect}"
              puts "  process_timeout: #{options[:process_timeout].inspect}"
            end
            Capybara::Cuprite::Driver.new(app, **options)
          end
        end

        def self.register_mobile_driver
          options = base_options.dup
          options[:window_size] = [375, 667]

          if ENV["GITHUB_ACTIONS"] == "true"
            options[:browser_options].merge!(ci_browser_options)
          end

          options[:logger] = console_logger if console_logger

          Capybara.register_driver :cuprite_mobile do |app|
            Capybara::Cuprite::Driver.new(app, **options)
          end
        end

        def self.setup!
          register_desktop_driver
          register_mobile_driver
          Capybara.default_driver = :cuprite
          Capybara.javascript_driver = :cuprite
        end
      end
    end
  end
end

Panda::Core::Testing::CupriteSetup.setup!
