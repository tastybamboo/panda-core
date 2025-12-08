# frozen_string_literal: true

require "capybara"
require "capybara/cuprite"
require "tmpdir"
require_relative "browser_path"
require_relative "browser_options"

module Panda
  module Core
    module Testing
      module Support
        module System
          # Cuprite Smoke Test
          #
          # Verifies that Cuprite can successfully:
          # - Create a driver instance
          # - Visit a data URI
          # - Execute JavaScript
          # - Read DOM content
          module CupriteSmoke
            class << self
              def fatal!(msg)
                warn "\n[Cuprite Fatal] #{msg}"
                abort("[Cuprite Fatal] Aborting: Cuprite cannot run reliably.\n")
              end

              def test!
                browser_options = BrowserOptions.default_options.dup
                browser_options["user-data-dir"] = Dir.mktmpdir("chrome-smoke")

                Capybara.register_driver(:panda_cuprite_smoke) do |app|
                  Capybara::Cuprite::Driver.new(
                    app,
                    browser_path: BrowserPath.resolve,
                    headless: true,
                    timeout: 10,
                    process_timeout: 10,
                    window_size: [1200, 800],
                    browser_options: browser_options
                  )
                end

                session = Capybara::Session.new(:panda_cuprite_smoke)

                session.visit("data:text/html,<h1 id='x'>Hello</h1>")

                fatal!("JS eval failed") unless session.evaluate_script("1 + 1") == 2
                fatal!("DOM read failed") unless session.find("#x").text == "Hello"

                puts "🐼 Cuprite smoke tests OK"
              rescue => e
                fatal!("Smoke test failed: #{e.class}: #{e.message}")
              end
            end
          end
        end
      end
    end
  end
end
