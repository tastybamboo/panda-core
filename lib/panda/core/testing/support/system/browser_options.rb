# frozen_string_literal: true

require "tmpdir"

module Panda
  module Core
    module Testing
      module Support
        module System
          # Default Browser Options (clean, Chrome.app-safe)
          #
          # Provides a comprehensive set of browser options for Chrome/Chromium
          # optimized for headless testing with minimal noise and resource usage.
          module BrowserOptions
            class << self
              def default_options
                return @default_options if defined?(@default_options)

                user_data_dir =
                  if ENV["CI"]
                    Dir.mktmpdir("chrome-ci-profile", "/tmp")
                  else
                    Dir.mktmpdir("chrome-profile")
                  end

                opts = {
                  "no-sandbox" => nil,
                  "disable-sync" => nil,
                  "disable-push-messaging" => nil,
                  "disable-notifications" => nil,
                  "disable-gcm-service-worker" => nil,
                  "disable-default-apps" => nil,
                  "disable-domain-reliability" => nil,
                  "disable-component-update" => nil,
                  "disable-background-networking" => nil,
                  "disable-cloud-import" => nil,
                  "no-first-run" => nil,
                  "no-default-browser-check" => nil,

                  # proper, minimal headless flags
                  "headless" => "new",

                  # Networking + CDP
                  "remote-debugging-port" => 0,

                  # Noise reduction
                  "log-level" => "3",
                  "v" => "0",

                  # Profiles
                  "user-data-dir" => user_data_dir,

                  # Features cleanup
                  "disable-features" => "Translate,MediaRouter,OptimizationGuideModelDownloading",

                  # no audio device needed
                  "mute-audio" => nil
                }

                @default_options = opts
              end
            end
          end
        end
      end
    end
  end
end
