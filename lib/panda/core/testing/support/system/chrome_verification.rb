# frozen_string_literal: true

require "tmpdir"
require_relative "browser_path"
require_relative "browser_options"

module Panda
  module Core
    module Testing
      module Support
        module System
          # Chrome Smoke Test (deterministic, minimal, Chrome.app safe)
          #
          # Verifies that Chrome/Chromium can start properly and create a WebSocket connection
          # for remote debugging. This is essential for ensuring Cuprite will work correctly.
          module ChromeVerification
            class << self
              def fatal!(msg)
                warn "\n[Cuprite Fatal] #{msg}"
                abort("[Cuprite Fatal] Aborting: Cuprite cannot run reliably.\n")
              end

              def verify!
                opts = BrowserOptions.default_options.dup
                tmpdir = Dir.mktmpdir("cuprite-verify")
                opts["user-data-dir"] = tmpdir

                cmd = [BrowserPath.resolve]

                opts.each do |k, v|
                  cmd << if v.nil?
                    "--#{k}"
                  else
                    "--#{k}=#{v}"
                  end
                end

                cmd << "about:blank"

                puts "[Chrome Smoke Test] Launching Chrome..."
                puts "[Chrome Smoke Test] CMD: #{cmd.inspect}"

                pid = Process.spawn(*cmd, out: File::NULL, err: File::NULL)

                devtools_file = File.join(tmpdir, "DevToolsActivePort")

                50.times do
                  break if File.exist?(devtools_file)
                  sleep 0.02
                end

                fatal!("Chrome smoke test failed — DevToolsActivePort missing") unless File.exist?(devtools_file)

                lines = File.read(devtools_file).split("\n")
                ws_url = "ws://127.0.0.1:#{lines.first}#{lines[1]}"

                puts "[Chrome Smoke Test] WebSocket URL: #{ws_url}"
                puts "[Chrome Smoke Test] OK"
              ensure
                begin
                  Process.kill("TERM", pid) if pid
                rescue
                end
              end
            end
          end
        end
      end
    end
  end
end
