# frozen_string_literal: true

require "capybara"

module Panda
  module Core
    module Testing
      module Support
        module System
          # Cuprite Warmup
          #
          # Warms up the Cuprite driver by visiting a test URL and verifying it responds.
          # This helps catch configuration issues early before the actual test suite runs.
          module CupriteWarmup
            class << self
              def fatal!(msg)
                warn "\n[Cuprite Fatal] #{msg}"
                abort("[Cuprite Fatal] Aborting: Cuprite cannot run reliably.\n")
              end

              def warmup!(driver_name: :panda_cuprite, url: nil)
                warmup_url = url || "#{Capybara.app_host}/admin/login"
                session = Capybara::Session.new(driver_name)
                session.visit(warmup_url)
                status = session.status_code

                fatal!("Warmup GET #{warmup_url} returned #{status}") unless status.between?(200, 399)
                puts "🐼 Warmup OK → #{warmup_url} (#{status})"
              rescue => e
                fatal!("Warmup exception: #{e.class}: #{e.message}")
              end
            end
          end
        end
      end
    end
  end
end
