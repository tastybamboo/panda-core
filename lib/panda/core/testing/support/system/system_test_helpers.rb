# frozen_string_literal: true

require_relative "cuprite_helpers"
require_relative "better_system_tests"

# Generic system test helpers for Cuprite-based testing
# These methods work for any Rails application using Cuprite

module Panda
  module Core
    module Testing
      module SystemTestHelpers
        include CupriteHelpers
        include BetterSystemTests
      end
    end
  end
end

# Configure RSpec to use these helpers
RSpec.configure do |config|
  config.include Panda::Core::Testing::SystemTestHelpers, type: :system

  # Make urls in mailers contain the correct server host
  config.around(:each, type: :system) do |ex|
    was_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] = Capybara.server_host
    ex.run
    Rails.application.default_url_options[:host] = was_host
  end

  # Make sure this hook runs before others
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
          ""
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

      sleep 0.5

      # Get comprehensive page info
      page_html = begin
        page.html
      rescue
        ""
      end
      current_url = begin
        page.current_url
      rescue
        ""
      end
      current_path = begin
        page.current_path
      rescue
        ""
      end
      page_title = begin
        page.title
      rescue
        ""
      end

      # Check for redirect or blank page indicators
      if page_html.length < 100
        puts "Warning: Page content appears minimal (#{page_html.length} chars) when taking screenshot"
      end

      # Use Capybara's save_screenshot method
      screenshot_path = Capybara.save_screenshot
      if screenshot_path
        puts "Screenshot saved to: #{screenshot_path}"
        puts "Page title: #{page_title}" if page_title.present?
        puts "Current URL: #{current_url}" if current_url.present?
        puts "Current path: #{current_path}" if current_path.present?
        puts "Page content length: #{page_html.length} characters"

        # Save page HTML for debugging in CI
        if ENV["GITHUB_ACTIONS"] && page_html.present?
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
