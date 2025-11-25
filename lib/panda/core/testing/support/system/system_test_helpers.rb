# frozen_string_literal: true

require_relative "cuprite_helpers"

# Generic system test helpers for Cuprite-based testing
# These methods work for any Rails application using Cuprite

module Panda
  module Core
    module Testing
      module SystemTestHelpers
        include CupriteHelpers
      end
    end
  end
end

# Configure RSpec to use these helpers
RSpec.configure do |config|
  config.include Panda::Core::Testing::SystemTestHelpers, type: :system

  tmp = ENV["TMPDIR"]
  if tmp && File.world_writable?(tmp)
    config.before(:suite) do
      warn "⚠️  TMPDIR is world-writable: #{tmp}"
    end
  end

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

  # CI-specific error handling with MultipleExceptionError detection
  config.around(:each, type: :system) do |example|
    exception = nil

    begin
      example.run
    rescue => e
      exception = e
    end

    # Also check example.exception in case RSpec aggregated exceptions there
    exception ||= example.exception

    # Handle MultipleExceptionError specially - don't retry, just report and skip
    if exception.is_a?(RSpec::Core::MultipleExceptionError)
      puts "\n" + ("=" * 80)
      puts "⚠️  MULTIPLE EXCEPTIONS - SKIPPING TEST (NO RETRY)"
      puts "=" * 80
      puts "Test: #{example.full_description}"
      puts "File: #{example.metadata[:file_path]}:#{example.metadata[:line_number]}"
      puts "Total exceptions: #{exception.all_exceptions.count}"
      puts "=" * 80

      # Group exceptions by class for cleaner output
      exceptions_by_class = exception.all_exceptions.group_by(&:class)
      exceptions_by_class.each do |klass, exs|
        puts "\n#{klass.name} (#{exs.count} occurrence#{"s" if exs.count > 1}):"
        puts "  #{exs.first.message.split("\n").first}"
      end

      puts "\n" + ("=" * 80)
      puts "⚠️  Skipping retry - moving to next test"
      puts "=" * 80 + "\n"

      # Mark this so after hooks can skip verbose output
      example.metadata[:multiple_exception_detected] = true

      # Re-raise to mark test as failed, but don't retry
      raise exception
    end

    # For other exceptions in CI, log and re-raise
    if exception && ENV["GITHUB_ACTIONS"] == "true"
      puts "[CI] Test error detected: #{exception.class} - #{exception.message}"
      puts "[CI] Current URL: #{begin
        page.current_url
      rescue
        ""
      end}"
      raise exception
    elsif exception
      # Not in CI, just re-raise
      raise exception
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

      name = example.metadata[:full_description].parameterize

      save_html!(name)

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
      screenshot_path = save_screenshot!(name)
      if screenshot_path
        puts "Screenshot saved to: #{screenshot_path}"
        puts "Page title: #{page_title}" if page_title.present?
        puts "Current URL: #{current_url}" if current_url.present?
        puts "Current path: #{current_path}" if current_path.present?
        puts "Page content length: #{page_html.length} characters"
      end
    rescue => e
      puts "Failed to capture screenshot: #{e.message}"
      # Skip verbose output if already handled by MultipleExceptionError handler
      unless example.metadata[:multiple_exception_detected]
        puts "Exception class: #{example.exception.class}"
        puts "Exception message: #{example.exception.message}"
      end
    end
  end
end
