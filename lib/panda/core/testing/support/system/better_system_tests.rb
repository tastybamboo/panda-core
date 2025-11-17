# frozen_string_literal: true

# Extends Rails system tests with improved screenshot and driver handling
#
# This module provides enhancements to Rails system tests:
# - Multi-session screenshot support
# - CI-specific error handling and logging
# - Enhanced failure screenshots with HTML debugging
# - Network idle waiting before screenshots
#
# @example Using in RSpec
#   RSpec.configure do |config|
#     config.include Panda::Core::Testing::BetterSystemTests, type: :system
#   end
module Panda
  module Core
    module Testing
      module BetterSystemTests
        # Make failure screenshots compatible with multi-session setup.
        # That's where we use Capybara.last_used_session introduced before.
        def take_screenshot
          return super unless Capybara.last_used_session

          Capybara.using_session(Capybara.last_used_session) { super }
        end

        module ClassMethods
          # Configure better system tests for RSpec
          # This sets up the necessary hooks and configuration
          def configure_better_system_tests!
            # Make urls in mailers contain the correct server host.
            # This is required for testing links in emails (e.g., via capybara-email).
            around(:each, type: :system) do |ex|
              was_host = Rails.application.default_url_options[:host]
              Rails.application.default_url_options[:host] = Capybara.server_host
              ex.run
              Rails.application.default_url_options[:host] = was_host
            end

            # Make sure this hook runs before others
            # Means you don't have to set js: true in every system spec
            prepend_before(:each, type: :system) do
              driven_by :cuprite
            end

            # Enable automatic screenshots on failure
            # Add CI-specific timeout and retry logic for form interactions
            # Includes MultipleExceptionError detection
            around(:each, type: :system) do |example|
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

            after(:each, type: :system) do |example|
              next unless example.exception

              begin
                # Wait for any pending JavaScript to complete
                # Cuprite has direct network idle support
                begin
                  page.driver.wait_for_network_idle
                rescue
                  nil
                end

                # Wait for DOM to be ready
                # sleep 0.5

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
                # Skip verbose output if already handled by MultipleExceptionError handler
                unless example.metadata[:multiple_exception_detected]
                  puts "Exception class: #{example.exception.class}"
                  puts "Exception message: #{example.exception.message}"
                end
              end
            end
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
        end
      end
    end
  end
end
