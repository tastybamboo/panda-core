# frozen_string_literal: true

# Generic system test helpers for Cuprite-based testing
# These methods work for any Rails application using Cuprite

module Panda
  module Core
    module Testing
      module SystemTestHelpers
        # Make failure screenshots compatible with multi-session setup
        def take_screenshot
          return super unless Capybara.last_used_session

          Capybara.using_session(Capybara.last_used_session) { super }
        end

        # Ensure page is loaded and stable before interacting
        def ensure_page_loaded
          # Check if we're on about:blank
          current_url = begin
            page.current_url
          rescue
            "unknown"
          end

          if current_url.include?("about:blank")
            puts "[CI] Page is on about:blank, skipping recovery to avoid loops" if ENV["GITHUB_ACTIONS"]
            return false
          end

          # Wait for page to be ready
          wait_for_ready_state
          true
        end

        # Wait for document ready state
        def wait_for_ready_state
          Timeout.timeout(5) do
            loop do
              ready = page.evaluate_script("document.readyState")
              break if ready == "complete"

              sleep 0.1
            end
          end
        rescue Timeout::Error
          puts "[CI] Timeout waiting for document ready state" if ENV["GITHUB_ACTIONS"]
        end

        # Waits for a specific selector to be present and visible
        # @param selector [String] CSS selector to wait for
        # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
        # @return [Boolean] true if element is found, false if timeout occurs
        def wait_for_selector(selector, timeout: 5)
          start_time = Time.now
          while Time.now - start_time < timeout
            return true if page.has_css?(selector, visible: true)

            sleep 0.1
          end
          false
        end

        # Waits for a specific text to be present on the page
        # @param text [String] Text to wait for
        # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
        # @return [Boolean] true if text is found, false if timeout occurs
        def wait_for_text(text, timeout: 5)
          start_time = Time.now
          while Time.now - start_time < timeout
            return true if page.has_text?(text)

            sleep 0.1
          end
          false
        end

        # Waits for network requests to complete
        # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
        # @return [Boolean] true if network is idle, false if timeout occurs
        def wait_for_network_idle(timeout: 5)
          page.driver.wait_for_network_idle(timeout: timeout)
          true
        rescue => e
          puts "[CI] Network idle timeout: #{e.message}" if ENV["GITHUB_ACTIONS"]
          false
        end

        # Waits for JavaScript to modify the DOM
        # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
        # @return [Boolean] true if mutation occurred, false if timeout occurs
        def wait_for_dom_mutation(timeout: 5)
          start_time = Time.now
          initial_dom = page.html
          while Time.now - start_time < timeout
            return true if page.html != initial_dom

            sleep 0.1
          end
          false
        end

        # Drop #pause anywhere in a test to stop the execution
        # Useful when you want to check out the contents of a web page in the middle of a test
        # running in a headful mode
        def pause
          page.driver.pause
        end

        # Drop #browser_debug anywhere in a test to open a Chrome inspector and pause the execution
        # Usage: browser_debug(binding)
        def browser_debug(*)
          page.driver.debug
        end

        # Allows sending a list of CSS selectors to be clicked on in the correct order (no delay)
        # Useful where you need to trigger e.g. a blur event on an input field
        def click_on_selectors(*css_selectors)
          css_selectors.each do |selector|
            find(selector).click
            sleep 0.1 # Add a small delay to allow JavaScript to run
          end
        end

        # Wait for a field to have a specific value
        # @param field_name [String] The field name or label
        # @param value [String] The expected value
        # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
        def wait_for_field_value(field_name, value, timeout: 5)
          start_time = Time.now
          while Time.now - start_time < timeout
            return true if page.has_field?(field_name, with: value)

            sleep 0.1
          end
          false
        end
      end
    end
  end
end

# Configure RSpec to use these helpers
RSpec.configure do |config|
  config.include Panda::Core::Testing::SystemTestHelpers, type: :system

  # Make URLs in mailers contain the correct server host
  # This is required for testing links in emails (e.g., via capybara-email)
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

  # CI-specific error handling
  config.around(:each, type: :system) do |example|
    if ENV["GITHUB_ACTIONS"] == "true"
      begin
        example.run
      rescue => e
        puts "[CI] Test error detected: #{e.class} - #{e.message}"
        puts "[CI] Current URL: #{begin
          page.current_url
        rescue
          "unknown"
        end}"
        raise e
      end
    else
      example.run
    end
  end

  # Enhanced screenshot capture on failure
  config.after(:each, type: :system) do |example|
    next unless example.exception

    begin
      # Wait for any pending JavaScript to complete
      begin
        page.driver.wait_for_network_idle
      rescue
        nil
      end

      sleep 0.5 # Wait for DOM to be ready

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

      # Warn about minimal page content
      if page_html.length < 100
        puts "Warning: Page content appears minimal (#{page_html.length} chars) when taking screenshot"
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
