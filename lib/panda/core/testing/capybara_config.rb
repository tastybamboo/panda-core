# frozen_string_literal: true

require "capybara/rspec"

module Panda
  module Core
    module Testing
      module CapybaraConfig
        def self.configure
          Capybara.server = :puma, {Silent: true}
          Capybara.default_max_wait_time = 5
          Capybara.disable_animation = true

          # Register Chrome driver with sensible defaults
          if defined?(Cuprite)
            Capybara.register_driver :panda_chrome do |app|
              Cuprite::Driver.new(
                app,
                window_size: [1400, 1400],
                browser_options: {
                  "no-sandbox": nil,
                  "disable-gpu": nil,
                  "disable-dev-shm-usage": nil
                },
                inspector: ENV["INSPECTOR"] == "true",
                headless: ENV["HEADLESS"] != "false"
              )
            end

            Capybara.javascript_driver = :panda_chrome
            Capybara.default_driver = :rack_test
          end
        end

        # Helper methods for system tests
        module Helpers
          def wait_for_ajax
            Timeout.timeout(Capybara.default_max_wait_time) do
              loop until page.evaluate_script("jQuery.active").zero?
            end
          rescue Timeout::Error
            # Ajax didn't finish, but continue anyway
          end

          def wait_for_turbo
            has_css?("html", wait: 0.1)
            return unless page.evaluate_script("typeof Turbo !== 'undefined'")

            page.evaluate_script("Turbo.session.drive = false")
            yield if block_given?
            page.evaluate_script("Turbo.session.drive = true")
          end

          def take_screenshot_on_failure
            return unless page.driver.respond_to?(:save_screenshot)

            timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
            filename = "screenshot_#{timestamp}_#{example.description.parameterize}.png"
            path = Rails.root.join("tmp", "screenshots", filename)

            FileUtils.mkdir_p(File.dirname(path))
            page.driver.save_screenshot(path)

            puts "\nScreenshot saved: #{path}"
          end
        end
      end
    end
  end
end
