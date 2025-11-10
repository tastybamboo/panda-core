# First, load Cuprite Capybara integration
require "ferrum"
require "capybara/cuprite"

# Configure Cuprite options (matching panda-cms working configuration)
cuprite_options = {
  window_size: [1440, 800],
  inspector: ENV["INSPECTOR"].in?(%w[y 1 yes true]),
  headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
  slowmo: ENV["SLOWMO"]&.to_f || 0,
  timeout: 30,
  js_errors: false,
  ignore_default_browser_options: false,
  process_timeout: 10,
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

# Add more permissive options in CI
if ENV["GITHUB_ACTIONS"] == "true"
  cuprite_options[:browser_options].merge!({
    "disable-web-security": nil,
    "allow-file-access-from-files": nil,
    "allow-file-access": nil
  })

  puts "\n🔍 Cuprite Configuration:"
  puts "   Debug mode: #{ENV["DEBUG"]}"
  puts "   Headless: #{cuprite_options[:headless]}"
  puts "   Browser options: #{cuprite_options[:browser_options].keys.join(" --")}"
  puts ""
end

# Register Cuprite driver
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, **cuprite_options)
end

# Configure Capybara to use cuprite driver by default
Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite

module CupriteHelpers
  # Drop #pause anywhere in a test to stop the execution.
  # Useful when you want to checkout the contents of a web page in the middle of a test
  # running in a headful mode.
  def pause
    page.driver.pause
  end

  # Drop #debug anywhere in a test to open a Chrome inspector and pause the execution
  # Usage: debug(binding)
  def debug(*)
    page.driver.debug(*)
  end

  # Allows sending a list of CSS selectors to be clicked on in the correct order (no delay)
  # Useful where you need to trigger e.g. a blur event on an input field
  def click_on_selectors(*css_selectors)
    css_selectors.each do |selector|
      page.driver.browser.at_css(selector).click
    end
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system

  config.before(:each, type: :system) do
    if respond_to?(:page) && page.driver.respond_to?(:browser)
      page.driver.browser.on(:console) do |message|
        puts "Browser #{message.type}: #{message.text}"
      end
    end
  end
end
