# frozen_string_literal: true

module Panda
  module Core
    module Testing
      module Support
        module System
          # Chrome/Chromium Browser Resolver
          #
          # Long-term stable resolution order:
          # 1. PANDA_CHROME_PATH override (always wins)
          # 2. macOS Chrome.app (best supported)
          # 3. macOS Chromium.app
          # 4. Homebrew Chromium (LAST — sandbox issues on macOS)
          # 5. Linux fallbacks (/usr/bin/google-chrome, chromium, etc.)
          module BrowserPath
            class << self
              # ----------------------------------------
              # Helpers
              # ----------------------------------------
              def fatal!(msg)
                warn "\n[Cuprite Fatal] #{msg}"
                abort("[Cuprite Fatal] Aborting: Cuprite cannot run reliably.\n")
              end

              def exists?(path)
                path && File.exist?(path)
              end

              # ----------------------------------------
              # macOS browser candidates (priority-ordered)
              # ----------------------------------------
              def mac_candidates
                [
                  # Best supported
                  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                  "#{ENV["HOME"]}/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",

                  # Chromium.app (next best)
                  "/Applications/Chromium.app/Contents/MacOS/Chromium",
                  "#{ENV["HOME"]}/Applications/Chromium.app/Contents/MacOS/Chromium",

                  # Homebrew chromium — LAST (sandbox issues)
                  "/opt/homebrew/bin/google-chrome",
                  "/opt/homebrew/bin/chromium"
                ]
              end

              # ----------------------------------------
              # Linux browser candidates
              # ----------------------------------------
              def linux_candidates
                %w[
                  /usr/bin/google-chrome
                  /usr/bin/google-chrome-stable
                  /usr/bin/chromium
                  /usr/bin/chromium-browser
                ]
              end

              # ----------------------------------------
              # Main Resolution Logic
              # ----------------------------------------
              def resolve
                return @browser_path if defined?(@browser_path)

                # 1. ENV override
                if (env = ENV["PANDA_CHROME_PATH"]).present?
                  fatal!("Browser path #{env.inspect} does not exist.") unless exists?(env)
                  puts "🐼 Chrome path (env): #{env}"
                  return @browser_path = env
                end

                # 2. macOS resolution
                if darwin?
                  app_path = mac_candidates.find { |p| exists?(p) }
                  if app_path
                    puts "🐼 Chrome path (macOS): #{app_path}"
                    return @browser_path = app_path
                  end
                end

                # 3. Linux fallbacks
                fallback = linux_candidates.find { |p| exists?(p) }

                fatal!("No Chrome/Chromium browser found on system") unless fallback

                puts "🐼 Chrome path (fallback): #{fallback}"
                @browser_path = fallback
              end

              # ----------------------------------------
              # Platform helpers
              # ----------------------------------------
              def darwin?
                RUBY_PLATFORM.include?("darwin")
              end
            end
          end
        end
      end
    end
  end
end
