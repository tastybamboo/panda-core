require "ferrum"
require "capybara/cuprite"
require "tmpdir"
require_relative "ferrum_console_logger"
require_relative "chrome_path"

module Panda
  module Core
    module Testing
      module CupriteSetup
        @console_logger = nil

        class << self
          attr_accessor :console_logger
        end

        def self.base_options
          ci_default_timeout = 30
          ci_default_process_timeout = 120
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

          browser_path = ENV["BROWSER_PATH"] || Panda::Core::Testing::Support::System::ChromePath.resolve

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
            pending_connection_errors: ENV["CI"] != "true",
            max_conns: 1,
            restart_if: {crashes: true, attempts: 2},
            browser_options: {
              "no-sandbox": nil,
              "disable-gpu": nil,
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
            "disable-web-security" => nil,
            "allow-file-access-from-files" => nil,
            "allow-file-access" => nil,
            "disable-dev-shm-usage" => nil, # Sets shared memory in /tmp; don't use if lots of /dev/shm space
            "no-sandbox" => nil
          }
        end

        def self.register_panda_cuprite_driver(name: :panda_cuprite, window_size: [1280, 720])
          options = base_options.dup
          options[:window_size] = window_size
          options[:browser_options] = options[:browser_options].dup
          options[:browser_options]["user-data-dir"] = Dir.mktmpdir("cuprite-profile")

          if ENV["CI"] == "true" # Covers both act and GitHub Actions
            options[:browser_options].merge!(ci_browser_options)
          end

          options[:logger] = console_logger if console_logger

          Capybara.register_driver name do |app|
            Capybara::Cuprite::Driver.new(app, **options)
          end
        end

        def self.setup!
          register_panda_cuprite_driver(name: :panda_cuprite, window_size: [1280, 720])
          register_panda_cuprite_driver(name: :panda_cuprite_mobile, window_size: [375, 667])
          Capybara.default_driver = :panda_cuprite
          Capybara.javascript_driver = :panda_cuprite
        end
      end
    end
  end
end

Capybara.default_max_wait_time = ENV.fetch("CAPYBARA_MAX_WAIT_TIME", "5").to_i
Capybara.raise_server_errors = true

# Server selection (overridable via env)
server_name = ENV.fetch("CAPYBARA_SERVER", "puma").to_sym
Capybara.server = server_name
Capybara.server_host = ENV.fetch("CAPYBARA_SERVER_HOST", "127.0.0.1")
# Allow dynamic port by leaving blank
port_env = ENV["CAPYBARA_PORT"]
Capybara.server_port = (port_env && !port_env.empty?) ? port_env.to_i : nil
app_host_env = ENV["CAPYBARA_APP_HOST"]
Capybara.app_host = app_host_env unless app_host_env.to_s.empty?
Capybara.always_include_port = !Capybara.app_host.nil?

HEADLESS = !(ENV["HEADFUL"] == "true")

# Register the drivers and setup the options
Panda::Core::Testing::CupriteSetup.setup!
