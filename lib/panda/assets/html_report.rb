# frozen_string_literal: true

module Panda
  module Assets
    class HTMLReport
      def self.write!(summary)
        path = Rails.root.join("spec/dummy/tmp/panda_assets_report.html")

        html = <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8" />
            <title>Panda Asset Report</title>
            <style>
              body { font-family: sans-serif; padding: 2rem; background: #f8fafc; }
              .card { background: white; padding: 1.5rem; border-radius: 8px; margin-bottom: 1.5rem; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
              .ok { color: #0a7f3f; font-weight: 600; }
              .fail { color: #b91c1c; font-weight: 600; }
              .engine { font-size: 1.25rem; margin-bottom: .5rem; }
              ul { margin-left: 1rem; }
            </style>
          </head>

          <body>
            <h1>Panda Asset Pipeline Report</h1>

            #{summary.entries.map { |e|
              <<~BLOCK
                <div class="card">
                  <div class="engine">#{e.engine.capitalize}</div>
                  <div>Status:
                    #{(e.prepare_ok && e.verify_ok) ? "<span class='ok'>OK</span>" : "<span class='fail'>FAILED</span>"}
                  </div>
                  <ul>
                    #{e.details.map { |d| "<li>#{d}</li>" }.join("\n")}
                  </ul>
                </div>
              BLOCK
            }.join("\n")}

          </body>
          </html>
        HTML

        FileUtils.mkdir_p(path.dirname)
        File.write(path, html)
        path
      end
    end
  end
end
