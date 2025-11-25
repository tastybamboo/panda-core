# frozen_string_literal: true

require "pathname"

# Helper methods for Cuprite-based system tests
#
# This module provides utility methods for working with Cuprite in system tests:
# - Page state verification helpers
# - Network and DOM waiting utilities
# - Safe form interaction methods with automatic retry in CI
# - Debugging helpers for headful testing
#
# @example Using in a system test
#   RSpec.configure do |config|
#     config.include Panda::Core::Testing::CupriteHelpers, type: :system
#   end
module Panda
  module Core
    module Testing
      module CupriteHelpers
        # Resolve the configured Capybara artifacts directory
        def capybara_artifacts_dir
          Pathname.new(Capybara.save_path || Rails.root.join("tmp/capybara"))
        end

        # Save a PNG screenshot for the current page.
        #
        def save_screenshot!(name = nil)
          name ||= example.metadata[:full_description].parameterize
          path = capybara_artifacts_dir.join("#{name}.png")

          FileUtils.mkdir_p(File.dirname(path))
          page.save_screenshot(path, full: true) # rubocop:disable Lint/Debugger
          puts "📸 Saved screenshot: #{path}"

          path
        end

        #
        # Record a small MP4 video of the test — uses Cuprite's Chrome DevTools API
        #
        def record_video!(name = nil, seconds: 3)
          name ||= example.metadata[:full_description].parameterize
          path = capybara_artifacts_dir.join("#{name}.mp4")

          FileUtils.mkdir_p(File.dirname(path))

          session = page.driver.browser
          client = session.client

          # Enable screencast
          client.command("Page.startScreencast", format: "png", quality: 80, maxWidth: 1280, maxHeight: 800)

          frames = []

          start = Time.now
          while Time.now - start < seconds
            message = client.listen
            if message["method"] == "Page.screencastFrame"
              frames << message["params"]["data"]
              client.command("Page.screencastFrameAck", sessionId: message["params"]["sessionId"])
            end
          end

          # Stop
          client.command("Page.stopScreencast")

          # Convert frames to MP4 using ffmpeg
          Dir.mktmpdir do |dir|
            png_dir = File.join(dir, "frames")
            FileUtils.mkdir_p(png_dir)

            frames.each_with_index do |data, i|
              File.binwrite(File.join(png_dir, "frame-%05d.png" % i), Base64.decode64(data))
            end

            system <<~CMD
              ffmpeg -y -framerate 8 -pattern_type glob -i '#{png_dir}/*.png' -c:v libx264 -pix_fmt yuv420p '#{path}'
            CMD
          end

          puts "🎥 Saved video: #{path}"
          path
        rescue => e
          puts "⚠️ Failed to record video: #{e.message}"
          nil
        end

        def save_html!(name = nil)
          name ||= example.metadata[:full_description].parameterize
          path = capybara_artifacts_dir.join("#{name}.html")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, page.html)
          puts "📝 Saved HTML snapshot: #{path}"
          path
        end

        # Ensure page is loaded and stable before interacting
        def ensure_page_loaded
          # Check if we're on about:blank and need to reload
          current_url = begin
            page.current_url
          rescue
            "unknown"
          end
          if current_url.include?("about:blank")
            puts "[CI] Page is on about:blank, skipping recovery to avoid loops" if ENV["GITHUB_ACTIONS"]
            # Don't try to recover - let the test handle it
            return false
          end

          # Wait for page to be ready
          wait_for_ready_state
          # Wait for JavaScript to load
          wait_for_javascript
          true
        end

        # Wait for document ready state
        def wait_for_ready_state
          Timeout.timeout(5) do
            loop do
              ready = page.evaluate_script("document.readyState")
              break if ready == "complete"

              # sleep 0.1
            end
          end
        rescue Timeout::Error
          puts "[CI] Timeout waiting for document ready state" if ENV["GITHUB_ACTIONS"]
        end

        # Wait for JavaScript to load (application-specific flag)
        # Override in your application if you have a custom loaded flag
        def wait_for_javascript(timeout: 5)
          Timeout.timeout(timeout) do
            loop do
              loaded = begin
                # Check for common JavaScript loaded indicators
                page.evaluate_script("document.readyState === 'complete'")
              rescue
                false
              end
              break if loaded

              # sleep 0.1
            end
          end
          true
        rescue Timeout::Error
          puts "[CI] Timeout waiting for JavaScript to load" if ENV["GITHUB_ACTIONS"]
          false
        end

        # Waits for a specific selector to be present and visible on the page
        # @param selector [String] CSS selector to wait for
        # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
        # @return [Boolean] true if element is found, false if timeout occurs
        def wait_for_selector(selector, timeout: 5)
          start_time = Time.now
          while Time.now - start_time < timeout
            return true if page.has_css?(selector, visible: true)

            # sleep 0.1
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

            # sleep 0.1
          end
          false
        end

        # Waits for network requests to complete
        # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
        # @return [Boolean] true if network is idle, false if timeout occurs
        def wait_for_network_idle(timeout: 5)
          # Cuprite has direct network idle support
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

            # sleep 0.1
          end
          false
        end

        # Drop #pause anywhere in a test to stop the execution.
        # Useful when you want to checkout the contents of a web page in the middle of a test
        # running in a headful mode.
        def pause
          # Cuprite-specific pause method
          page.driver.pause
        end

        # Drop #browser_debug anywhere in a test to open a Chrome inspector and pause the execution
        # Usage: browser_debug(binding)
        def browser_debug(*)
          # Cuprite-specific debug method
          page.driver.debug
        end

        # Allows sending a list of CSS selectors to be clicked on in the correct order (no delay)
        # Useful where you need to trigger e.g. a blur event on an input field
        def click_on_selectors(*css_selectors)
          css_selectors.each do |selector|
            find(selector).click
            # sleep 0.1 # Add a small delay to allow JavaScript to run
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

            # sleep 0.1
          end
          false
        end

        # Safe methods that handle Ferrum NodeNotFoundError in CI
        def safe_fill_in(locator, with:)
          retries = 0
          start_time = Time.now
          max_duration = 5 # Maximum 5 seconds total

          begin
            fill_in locator, with: with
          rescue Ferrum::NodeNotFoundError, Capybara::ElementNotFound => e
            retries += 1
            elapsed = Time.now - start_time

            if retries <= 2 && elapsed < max_duration && ENV["GITHUB_ACTIONS"]
              puts "[CI] Element not found on fill_in '#{locator}', retry #{retries}/2 (#{elapsed.round(1)}s elapsed)"
              # sleep 0.5
              retry
            else
              puts "[CI] Giving up on fill_in '#{locator}' after #{retries} retries and #{elapsed.round(1)}s" if ENV["GITHUB_ACTIONS"]
              raise e
            end
          end
        end

        def safe_select(value, from:)
          retries = 0
          start_time = Time.now
          max_duration = 5 # Maximum 5 seconds total

          begin
            select value, from: from
          rescue Ferrum::NodeNotFoundError, Capybara::ElementNotFound => e
            retries += 1
            elapsed = Time.now - start_time

            if retries <= 2 && elapsed < max_duration && ENV["GITHUB_ACTIONS"]
              puts "[CI] Element not found on select '#{value}' from '#{from}', retry #{retries}/2 (#{elapsed.round(1)}s elapsed)"
              # sleep 0.5
              retry
            else
              puts "[CI] Giving up on select '#{value}' from '#{from}' after #{retries} retries and #{elapsed.round(1)}s" if ENV["GITHUB_ACTIONS"]
              raise e
            end
          end
        end

        def safe_click_button(locator)
          retries = 0
          start_time = Time.now
          max_duration = 5 # Maximum 5 seconds total

          begin
            click_button locator
          rescue Ferrum::NodeNotFoundError, Capybara::ElementNotFound => e
            retries += 1
            elapsed = Time.now - start_time

            if retries <= 2 && elapsed < max_duration && ENV["GITHUB_ACTIONS"]
              puts "[CI] Element not found on click_button '#{locator}', retry #{retries}/2 (#{elapsed.round(1)}s elapsed)"
              # sleep 0.5
              retry
            else
              puts "[CI] Giving up on click_button '#{locator}' after #{retries} retries and #{elapsed.round(1)}s" if ENV["GITHUB_ACTIONS"]
              raise e
            end
          end
        end
      end
    end
  end
end
