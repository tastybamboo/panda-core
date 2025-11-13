# frozen_string_literal: true

require "fileutils"
require "erb"

module Panda
  module Core
    module Testing
      module Assets
        class Report
          attr_reader :config, :timings, :checks, :html_sections

          def initialize(config)
            @config = config
            @timings = {}
            @checks = {}
            @html_sections = []
          end

          # Simple timing helper
          def time(key)
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            result = yield
            finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            @timings[key] = (finish - start).round(2)
            result
          end

          # Record a check outcome (for the summary table)
          def check(key, ok)
            @checks[key] = ok
          end

          # ASCII banner box
          def banner(title)
            width = title.length + 2
            puts "┌#{"─" * width}┐"
            puts "│#{title}│"
            puts "└#{"─" * width}┘"
            @html_sections << "<h2>#{ERB::Util.html_escape(title.strip)}</h2>"
          end

          # Section header
          def section(title)
            width = title.length + 2
            puts "┌#{"─" * width}┐"
            puts "│ #{title} │"
            puts "└#{"─" * width}┘"
            @html_sections << "<h3>#{ERB::Util.html_escape(title)}</h3>"
          end

          # Log a bullet point (and mirror into HTML)
          def log(line)
            puts line
            @html_sections << "<pre>#{ERB::Util.html_escape(line)}</pre>"
          end

          # Final summary + HTML report
          def finish!(prepare_ok:, verify_ok:)
            puts "------------------------------------------------------------"
            puts "• Summary for #{config.engine_label}"
            puts "   #{status_mark(prepare_ok)} Prepare phase #{prepare_ok ? "OK" : "FAILED"}"
            puts "   #{status_mark(verify_ok)} Verify phase #{verify_ok ? "OK" : "FAILED"}"
            puts "• Timings:"
            @timings.each do |key, value|
              puts "   ✓ #{key}: #{value}s"
            end

            write_html_report(prepare_ok: prepare_ok, verify_ok: verify_ok)
          end

          private

          def status_mark(ok)
            ok ? "✓" : "✗"
          end

          def write_html_report(prepare_ok:, verify_ok:)
            tmp_dir = config.dummy_root.join("tmp")
            FileUtils.mkdir_p(tmp_dir)
            path = tmp_dir.join("panda_assets_report.html")

            html = <<~HTML
              <!doctype html>
              <html>
              <head>
                <meta charset="utf-8">
                <title>#{ERB::Util.html_escape(config.engine_label)} asset report</title>
                <style>
                  body { font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif; padding: 2rem; background: #fafafa; color: #111; }
                  h1, h2, h3 { margin-top: 1.5rem; }
                  pre { background: #111; color: #0f0; padding: 0.5rem 0.75rem; border-radius: 4px; font-size: 13px; overflow-x: auto; }
                  .summary { margin-top: 1rem; padding: 1rem; border-radius: 6px; background: #fff; box-shadow: 0 0 0 1px #eee; }
                  .summary-ok { border-left: 4px solid #16a34a; }
                  .summary-fail { border-left: 4px solid #dc2626; }
                  table { border-collapse: collapse; margin-top: 1rem; }
                  th, td { border: 1px solid #ddd; padding: 0.5rem 0.75rem; font-size: 13px; }
                  th { background: #f3f4f6; text-align: left; }
                  .pill-ok { color: #166534; background: #bbf7d0; padding: 2px 6px; border-radius: 999px; font-size: 11px; }
                  .pill-fail { color: #b91c1c; background: #fecaca; padding: 2px 6px; border-radius: 999px; font-size: 11px; }
                </style>
              </head>
              <body>
                <h1>#{ERB::Util.html_escape(config.engine_label)} – dummy asset report</h1>
                <div class="summary #{(prepare_ok && verify_ok) ? "summary-ok" : "summary-fail"}">
                  <p><strong>Prepare:</strong> #{prepare_ok ? "OK" : "FAILED"}</p>
                  <p><strong>Verify:</strong> #{verify_ok ? "OK" : "FAILED"}</p>
                  <table>
                    <thead>
                      <tr>
                        <th>Check</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      #{checks.map { |k, ok|
                        "<tr><td>#{ERB::Util.html_escape(k.to_s)}</td><td><span class=\"#{ok ? "pill-ok" : "pill-fail"}\">#{ok ? "OK" : "FAILED"}</span></td></tr>"
                      }.join}
                    </tbody>
                  </table>
                  <h3>Timings</h3>
                  <table>
                    <thead><tr><th>Stage</th><th>Seconds</th></tr></thead>
                    <tbody>
                      #{timings.map { |k, v| "<tr><td>#{ERB::Util.html_escape(k.to_s)}</td><td>#{v}</td></tr>" }.join}
                    </tbody>
                  </table>
                </div>
                #{@html_sections.join("\n")}
              </body>
              </html>
            HTML

            File.write(path, html)
            puts "• HTML report written to #{path}"
          end
        end
      end
    end
  end
end
