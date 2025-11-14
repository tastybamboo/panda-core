# frozen_string_literal: true

require "fileutils"

module Panda
  module Assets
    class HTMLReport
      REPORT_PATH = "spec/dummy/tmp/panda_assets_report.html"

      class << self
        #
        # Write the full HTML report to the dummy app
        #
        def write!(summary)
          full_path = Rails.root.join(REPORT_PATH)
          FileUtils.mkdir_p(full_path.dirname)
          File.write(full_path, html(summary))
        end

        #
        # Build the entire HTML document
        #
        def html(summary)
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
              <head>
                <meta charset="utf-8" />
                <title>Panda Asset Pipeline Report</title>
                <style>
                  body { font-family: ui-sans-serif, system-ui; padding: 2rem; background: #f8fafc; }
                  h1 { font-size: 2rem; margin-bottom: 1rem; color: #0f172a; }
                  .ok { color: #16a34a; }
                  .fail { color: #dc2626; }
                  table { width: 100%; border-collapse: collapse; margin-top: 1.5rem; }
                  th { background: #f1f5f9; text-align: left; padding: 0.75rem; }
                  td { padding: 0.75rem; border-bottom: 1px solid #e2e8f0; }
                  .details { color: #64748b; font-size: 0.875rem; }
                  .badge { padding: 0.25rem 0.5rem; border-radius: 0.375rem; font-size: 0.75rem; }
                  .badge-ok { background: #dcfce7; color: #166534; }
                  .badge-fail { background: #fee2e2; color: #991b1b; }
                </style>
              </head>

              <body>
                <h1>Panda Asset Verification Report</h1>

                <p>
                  Status:
                  <strong class="#{summary.ok? ? "status-ok" : "status-fail"}">
                    #{summary.ok? ? "OK" : "FAILED"}
                  </strong>
                </p>

                #{build_results_table(summary)}
                #{build_timings_table(summary)}

              </body>
            </html>
          HTML
        end

        private

        #
        # Build the main verification table
        #
        def build_results_table(summary)
          rows = summary.results.map do |r|
            icon = r.ok ? "✓" : "✗"
            klass = r.ok ? "status-ok" : "status-fail"
            details = r.details ? "<div class='details'>#{r.details}</div>" : ""

            <<~ROW
              <tr>
                <td><strong>#{r.step}</strong>#{details}</td>
                <td class="#{klass}"><strong>#{icon}</strong></td>
              </tr>
            ROW
          end.join("\n")

          <<~TABLE
            <h2>Prepare & Verify Steps</h2>
            <table>
              <thead>
                <tr>
                  <th>Step</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                #{rows}
              </tbody>
            </table>
          TABLE
        end

        #
        # Build timing table
        #
        def build_timings_table(summary)
          return "" if summary.timings.empty?

          rows = summary.timings.map do |step, sec|
            <<~ROW
              <tr>
                <td>#{step}</td>
                <td>#{format("%.3f", sec)}s</td>
              </tr>
            ROW
          end.join("\n")

          <<~TABLE
            <h2>Timings</h2>
            <table>
              <thead>
                <tr>
                  <th>Step</th>
                  <th>Seconds</th>
                </tr>
              </thead>
              <tbody>
                #{rows}
              </tbody>
            </table>
          TABLE
        end
      end
    end
  end
end
