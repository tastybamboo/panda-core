# frozen_string_literal: true

# CI-specific Capybara configuration
# This file configures Capybara for GitHub Actions and other CI environments
# It uses a more robust Puma setup with compatibility for Puma 6 and 7+

return unless defined?(Capybara)

ci_mode = ENV["GITHUB_ACTIONS"] == "true" || ENV["CI_SYSTEM_SPECS"] == "true"
return unless ci_mode

require "rack/handler/puma"

RSpec.configure do |config|
  config.before(:suite) do
    Capybara.server = :puma_ci
    Capybara.default_max_wait_time = Integer(ENV.fetch("CAPYBARA_MAX_WAIT_TIME", 5))

    port = Integer(ENV.fetch("CAPYBARA_PORT", 3001))
    Capybara.server_host = "127.0.0.1"
    Capybara.server_port = port
    Capybara.app_host = "http://127.0.0.1:#{port}"
    Capybara.always_include_port = true

    puts "[CI Config] Capybara.server      = #{Capybara.server.inspect}"
    puts "[CI Config] Capybara.app_host    = #{Capybara.app_host.inspect}"
    puts "[CI Config] Capybara.server_host = #{Capybara.server_host.inspect}"
    puts "[CI Config] Capybara.server_port = #{Capybara.server_port.inspect}"
    puts "[CI Config] Capybara.max_wait    = #{Capybara.default_max_wait_time}s"
  end
end

Capybara.register_server :puma_ci do |app, port, host|
  puts "[CI Config] Starting Puma (single mode) on #{host}:#{port}"

  min_threads = Integer(ENV.fetch("PUMA_MIN_THREADS", "2"))
  max_threads = Integer(ENV.fetch("PUMA_MAX_THREADS", "2"))

  options = {
    Host: host,
    Port: port,
    Threads: "#{min_threads}:#{max_threads}",
    Workers: 0,
    Silent: !ENV["RSPEC_DEBUG"],
    Verbose: ENV["RSPEC_DEBUG"],
    PreloadApp: false
  }

  # --- Puma Compatibility Layer (supports Puma 6 AND Puma 7+) ---
  puma_run = Rack::Handler::Puma.method(:run)

  if puma_run.arity == 2
    # Puma <= 6.x signature:
    #   run(app, options_hash)
    puts "[CI Config] Using Puma <= 6 API (arity 2)"
    Rack::Handler::Puma.run(app, options)
  else
    # Puma >= 7.x signature:
    #   run(app, **options)
    puts "[CI Config] Using Puma >= 7 API (keyword args)"
    Rack::Handler::Puma.run(app, **options)
  end
end
