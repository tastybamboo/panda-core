# frozen_string_literal: true

require "json"

module Panda
  module Core
    module Testing
      module Support
        module System
          # Custom logger for capturing browser console messages via Ferrum/Cuprite
          # Ferrum doesn't provide a direct API for console messages - instead it uses
          # Chrome DevTools Protocol (CDP) events that are sent to a logger object
          class FerrumConsoleLogger
            attr_reader :logs

            def initialize
              @logs = []
            end

            # Ferrum calls this method with CDP protocol events
            # Format: "SEND message_id {json}" or "RECV message_id {json}"
            def puts(log_str)
              return unless log_str.is_a?(String)

              parts = log_str.strip.split(" ", 3)
              return if parts.size < 3

              # Parse the JSON data from CDP event
              data = JSON.parse(parts[2])

              # Only capture console-related events
              if console_event?(data)
                @logs << Message.new(log_str)
              end
            rescue JSON::ParserError
              # Silently ignore malformed JSON
            end

            def clear
              @logs.clear
            end

            private

            def console_event?(data)
              %w[
                Runtime.exceptionThrown
                Log.entryAdded
                Runtime.consoleAPICalled
              ].include?(data["method"])
            end

            # Wrapper for a single console message
            class Message
              def initialize(log_str)
                parts = log_str.strip.split(" ", 3)
                @raw = log_str
                @data = JSON.parse(parts[2])
              end

              # Get the log level (error, warning, info, etc.)
              def level
                # Different CDP events structure level differently
                @data.dig("params", "entry", "level") ||
                  @data.dig("params", "type") ||
                  "log"
              end

              # Get the message text
              def message
                # Handle different CDP event types
                if @data["method"] == "Runtime.exceptionThrown"
                  exception = @data.dig("params", "exceptionDetails")
                  if exception
                    text = exception.dig("exception", "description") || exception["text"]
                    location = "#{exception.dig("url")}:#{exception.dig("lineNumber")}"
                    "#{text} (#{location})"
                  else
                    "Unknown exception"
                  end
                elsif @data["method"] == "Log.entryAdded"
                  @data.dig("params", "entry", "text") || ""
                elsif @data["method"] == "Runtime.consoleAPICalled"
                  # Console API calls have arguments that need to be extracted
                  args = @data.dig("params", "args") || []
                  args.map { |arg| format_argument(arg) }.join(" ")
                else
                  @raw
                end
              end

              # Format a CDP RemoteObject argument
              def format_argument(arg)
                case arg["type"]
                when "string"
                  arg["value"]
                when "number", "boolean"
                  arg["value"].to_s
                when "undefined"
                  "undefined"
                when "object"
                  if arg["subtype"] == "null"
                    "null"
                  else
                    arg["description"] || "[Object]"
                  end
                else
                  arg["description"] || arg.inspect
                end
              end

              def to_s
                "[#{level.upcase}] #{message}"
              end
            end
          end
        end
      end
    end
  end
end
