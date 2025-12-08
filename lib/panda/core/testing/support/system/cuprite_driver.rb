# frozen_string_literal: true

# =============================================================================
# Panda Core — Fully Integrated Cuprite Driver + Diagnostics
# =============================================================================
#
# This file provides a complete Cuprite driver setup with:
# - HOME directory management for sandboxed environments
# - Browser path resolution (Chrome.app → chromium → google-chrome)
# - Chrome smoke testing and verification
# - Cuprite smoke testing
# - Warmup capabilities
# - DevTools recording for debugging
# - RSpec integration hooks
#
# All components are modular and can be used independently.

require "ferrum"
require "capybara"
require "capybara/cuprite"
require "tmpdir"
require "fileutils"
require "json"

return unless defined?(Capybara)

# Load all modular components
require_relative "home_dir"
require_relative "browser_path"
require_relative "browser_options"
require_relative "chrome_verification"
require_relative "cuprite_smoke"
require_relative "cuprite_warmup"
require_relative "devtools_recorder"

# =============================================================================
# Initialize HOME directory override
# =============================================================================

Panda::Core::Testing::Support::System::HomeDir.ensure_writable_home!

# =============================================================================
# Capybara Configuration
# =============================================================================

Capybara.default_max_wait_time = 5
Capybara.server_host = "0.0.0.0"
Capybara.always_include_port = true
Capybara.reuse_server = true
Capybara.raise_server_errors = true

# =============================================================================
# Capybara Driver Registration
# =============================================================================

Capybara.register_driver(:panda_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    browser_path: Panda::Core::Testing::Support::System::BrowserPath.resolve,
    headless: true,
    timeout: 30,
    process_timeout: 30,
    js_errors: true,
    window_size: [1200, 800],
    browser_options: Panda::Core::Testing::Support::System::BrowserOptions.default_options
  )
end

Capybara.default_driver = :panda_cuprite
Capybara.javascript_driver = :panda_cuprite

# =============================================================================
# RSpec Integration
# =============================================================================

if defined?(RSpec)
  RSpec.configure do |config|
    config.append_before(:suite) do
      # Verify Chrome can start
      Panda::Core::Testing::Support::System::ChromeVerification.verify!

      # Boot Capybara server
      server = Capybara::Server.new(Capybara.app, port: nil, host: Capybara.server_host)
      server.boot

      Capybara.app_host = "http://#{server.host}:#{server.port}"
      puts "🐼 Capybara server running at #{Capybara.app_host}"

      # Run Cuprite smoke tests
      Panda::Core::Testing::Support::System::CupriteSmoke.test!

      # Warmup Cuprite (only if you have an /admin/login route)
      begin
        Panda::Core::Testing::Support::System::CupriteWarmup.warmup!
      rescue => e
        # Warmup is optional - if /admin/login doesn't exist, continue anyway
        puts "🐼 Warmup skipped: #{e.message}"
      end
    end

    config.append_after(:suite) do
      # Restore original HOME directory
      Panda::Core::Testing::Support::System::HomeDir.restore_home!
    end
  end
end
