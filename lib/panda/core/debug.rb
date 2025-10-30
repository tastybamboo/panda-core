# frozen_string_literal: true

module Panda
  module Core
    module Debug
      class << self
        # Check if debug mode is enabled via PANDA_DEBUG environment variable
        def enabled?
          ENV["PANDA_DEBUG"].to_s.downcase == "true" || ENV["PANDA_DEBUG"] == "1"
        end

        # Log a debug message if debug mode is enabled
        def log(message, prefix: "PANDA")
          return unless enabled?

          timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
          puts "[#{prefix} DEBUG #{timestamp}] #{message}"
        end

        # Log an object with pretty printing (using awesome_print if available)
        def inspect(object, label: nil, prefix: "PANDA")
          return unless enabled?

          timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
          header = label ? "#{label}: " : ""

          puts "\n[#{prefix} DEBUG #{timestamp}] #{header}"
          if defined?(AwesomePrint)
            ap object
          else
            pp object
          end
          puts
        end

        # Enable HTTP debugging for Net::HTTP requests
        def enable_http_debug!
          return unless enabled? || ENV["DEBUG_HTTP"].to_s.downcase == "true"

          require "net/http"
          Net::HTTP.set_debug_output($stdout)
          log("HTTP debugging enabled - all HTTP requests will be logged")
        end
      end
    end
  end
end
