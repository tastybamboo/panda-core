# frozen_string_literal: true

# Extends Rails system tests with improved screenshot and driver handling
module BetterRailsSystemTests
  # Make failure screenshots compatible with multi-session setup.
  # That's where we use Capybara.last_used_session introduced before.
  def take_screenshot
    return super unless Capybara.last_used_session

    Capybara.using_session(Capybara.last_used_session) { super }
  end
end

RSpec.configure do |config|
  config.include BetterRailsSystemTests, type: :system

  # Make urls in mailers contain the correct server host.
  # This is required for testing links in emails (e.g., via capybara-email).
  config.around(:each, type: :system) do |ex|
    was_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] = Capybara.server_host
    ex.run
    Rails.application.default_url_options[:host] = was_host
  end

  # Make sure this hook runs before others
  # Means you don't have to set js: true in every system spec
  config.prepend_before(:each, type: :system) do
    driven_by :cuprite
  end

  # Set up Current attributes and URL configuration after Capybara is ready
  config.before(:each, type: :system) do
    # Don't force visit in CI - it causes browser resets
    # Instead, let the first visit in the test handle server startup

    # Set default URL configuration
    Panda::Core::Current.root = "http://127.0.0.1:#{Capybara.server_port || 3001}"
    Rails.application.routes.default_url_options[:host] = Panda::Core::Current.root

    # Set other Current attributes that might be needed
    Panda::Core::Current.request_id = SecureRandom.uuid
    Panda::Core::Current.user_agent = "Test User Agent"
    Panda::Core::Current.ip_address = "127.0.0.1"
    Panda::Core::Current.user = nil
  end

  # Add CI-specific error handling and debugging
  config.around(:each, type: :system) do |example|
    if ENV["GITHUB_ACTIONS"] == "true"
      # In CI, wrap the test execution with additional error handling
      begin
        example.run
      rescue => e
        # Log any error for debugging
        puts "[CI] Test error detected: #{e.class} - #{e.message}"
        puts "[CI] Current URL: #{begin
          page.current_url
        rescue
          "unknown"
        end}"

        # Re-raise the original error
        raise e
      end
    else
      example.run
    end
  end

  config.after(:each, type: :system) do |example|
    if example.exception
      begin
        # Wait for any pending JavaScript to complete
        begin
          page.driver.wait_for_network_idle
        rescue
          nil
        end

        # Wait for DOM to be ready
        sleep 0.5

        # Get comprehensive page info
        page_html = begin
          page.html
        rescue
          "<html><body>Error loading page</body></html>"
        end

        page_title = begin
          page.title
        rescue
          "N/A"
        end

        # Use Capybara's save_screenshot method
        screenshot_path = Capybara.save_screenshot
        if screenshot_path
          puts "Screenshot saved to: #{screenshot_path}"
          puts "Page title: #{page_title}"
          puts "Page content length: #{page_html.length} characters"

          # Save page HTML for debugging in CI
          if ENV["GITHUB_ACTIONS"]
            html_debug_path = screenshot_path.gsub(".png", ".html")
            File.write(html_debug_path, page_html)
            puts "Page HTML saved to: #{html_debug_path}"
          end
        end
      rescue => e
        puts "Failed to capture screenshot: #{e.message}"
        puts "Exception class: #{example.exception.class}"
        puts "Exception message: #{example.exception.message}"
      end
    end
  end
end
