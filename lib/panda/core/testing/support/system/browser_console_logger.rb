# frozen_string_literal: true

# Capture and log browser console output for debugging CI failures
module BrowserConsoleLogger
  def self.included(base)
    base.after do |example|
      # Only log console in CI when test fails
      next unless ENV["CI"] && example.exception

      if respond_to?(:page) && page.driver.is_a?(Capybara::Cuprite::Driver)
        begin
          console_logger = Panda::Core::Testing::CupriteSetup.console_logger if defined?(Panda::Core::Testing::CupriteSetup)

          unless console_logger
            puts "\n⚠️  Console logger not available"
            next
          end

          console_logs = console_logger.logs

          if console_logs.any?
            puts "\n" + "=" * 80
            puts "BROWSER CONSOLE OUTPUT (#{console_logs.length} messages)"
            puts "=" * 80

            console_logs.each_with_index do |msg, index|
              level = msg.level.downcase
              type_icon = case level
              when "error" then "❌"
              when "warning" then "⚠️"
              when "info" then "ℹ️"
              else "📝"
              end

              puts "#{index + 1}. #{type_icon} #{msg}"
              puts ""
            end

            puts "=" * 80
          else
            puts "\n⚠️  No console messages captured (browser may not have started)"
          end
        rescue => e
          puts "\n⚠️  Failed to capture console logs: #{e.message}"
          puts "   #{e.class}: #{e.backtrace.first(3).join("\n   ")}" if ENV["DEBUG"]
        end
      end
    end
  end
end

# Include in all system tests
RSpec.configure do |config|
  config.include BrowserConsoleLogger, type: :system
end
