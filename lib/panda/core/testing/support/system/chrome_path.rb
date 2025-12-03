# frozen_string_literal: true

module Panda
  module Core
    module Testing
      module Support
        module System
          module ChromePath
            def self.resolve
              @resolved ||= begin
                candidates = [
                  # Linux (Debian/Ubuntu + your CI image)
                  "/usr/bin/chromium",
                  "/usr/bin/chromium-browser",
                  "/usr/bin/google-chrome",
                  "/opt/google/chrome/google-chrome",
                  "/opt/google/chrome/chrome",

                  # macOS Homebrew paths (Chromium)
                  "/opt/homebrew/bin/chromium",
                  "/usr/local/bin/chromium",

                  # macOS Google Chrome
                  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                  "/Applications/Chromium.app/Contents/MacOS/Chromium",
                  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
                ]

                candidates.find { |path| File.executable?(path) } ||
                  raise("Could not find a Chrome/Chromium binary on this system")
              end
            end
          end
        end
      end
    end
  end
end
