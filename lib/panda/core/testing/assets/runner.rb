# frozen_string_literal: true

require_relative "preparer"
require_relative "verifier"
require "erb"
require "fileutils"

module Panda
  module Core
    module Testing
      module Assets
        class Runner
          TEMPLATE = <<~HTML
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="UTF-8">
              <title>Panda <%= engine.capitalize %> – Asset Report</title>
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 2rem; }
                h1 { margin-bottom: 1rem; }
                table { border-collapse: collapse; width: 100%; margin: 2rem 0; }
                th, td { border: 1px solid #ddd; padding: 8px; }
                th { background: #f0f0f0; }
                .fail { color: #c00; font-weight: bold; }
                .ok { color: #0a0; font-weight: bold; }
              </style>
            </head>
            <body>
              <h1>Panda <%= engine.capitalize %> – Dummy Asset Report</h1>

              <h2>Prepare: <%= prepare_ok ? "OK" : "FAILED" %></h2>
              <h2>Verify:  <%= verify_ok ? "OK" : "FAILED" %></h2>

              <table>
                <tr><th>Check</th><th>Status</th></tr>
                <% statuses.each do |name, status| %>
                  <tr>
                    <td><%= name %></td>
                    <td class="<%= status == "OK" ? "ok" : "fail" %>"><%= status %></td>
                  </tr>
                <% end %>
              </table>

              <h2>Timings</h2>
              <table>
                <tr><th>Stage</th><th>Seconds</th></tr>
                <% timings.each do |name, t| %>
                  <tr><td><%= name %></td><td><%= t %></td></tr>
                <% end %>
              </table>
            </body>
            </html>
          HTML

          def self.run(engine)
            new(engine).run
          end

          attr_reader :engine, :status

          def initialize(engine)
            @engine = engine
            @status = {}
          end

          def run
            prepare_ok = false
            verify_ok = false

            # ---------------------------------------------
            # PREPARE PHASE
            # ---------------------------------------------
            begin
              preparer = Preparer.new(engine)
              preparer.prepare
              @prepare_timings = preparer.timings
              prepare_ok = true
            rescue => e
              puts "❌ Prepare failed: #{e.message}"
              prepare_ok = false
            end

            # ---------------------------------------------
            # VERIFY PHASE
            # ---------------------------------------------
            begin
              verifier = Verifier.new(engine)
              verifier.verify
              @verify_timings = verifier.timings
              verify_ok = true
            rescue => e
              puts "❌ Verify failed: #{e.message}"
              verify_ok = false
            end

            # ---------------------------------------------
            # Combine results + write HTML report
            # ---------------------------------------------
            write_report(
              prepare_ok: prepare_ok,
              verify_ok: verify_ok
            )

            exit(1) unless prepare_ok && verify_ok
          end

          def write_report(prepare_ok:, verify_ok:)
            dummy = resolve_dummy_root
            outdir = dummy.join("tmp")
            FileUtils.mkdir_p(outdir)
            outfile = outdir.join("panda_assets_report.html")

            statuses = {
              "prepare" => prepare_ok ? "OK" : "FAILED",
              "verify" => verify_ok ? "OK" : "FAILED"
            }

            timings = (@prepare_timings || {}).merge(@verify_timings || {})

            html = ERB.new(TEMPLATE).result(
              binding
            )

            File.write(outfile, html)
            puts "• HTML report written to #{outfile}"
          end

          def resolve_dummy_root
            root = Rails.root
            return root if root.basename.to_s == "dummy"
            candidate = root.join("spec/dummy")
            return candidate if candidate.exist?
            raise "Could not locate dummy root"
          end
        end
      end
    end
  end
end
