# frozen_string_literal: true

require "erb"
require "fileutils"
require "json"

module Panda
  module Assets
    class HTMLReport
      TEMPLATE_VERSION = "1.0.0"

      attr_reader :engine_key, :dummy_root, :checks, :timings, :manifest, :importmap,
        :js_resolution, :errors

      def initialize(engine_key:, dummy_root:, checks:, timings:, manifest:, importmap:, js_resolution:, errors:)
        @engine_key = engine_key
        @dummy_root = dummy_root
        @checks = checks
        @timings = timings
        @manifest = manifest || {}
        @importmap = importmap || {}
        @js_resolution = js_resolution || {}
        @errors = errors || []
      end

      def write!
        report_dir = dummy_root.join("tmp")
        FileUtils.mkdir_p(report_dir)
        path = report_dir.join("panda_assets_report.html")
        File.write(path, render)
        path
      end

      private

      def render
        ok_prepare = checks.fetch(:prepare_propshaft, true) &&
          checks.fetch(:prepare_copy_js, true) &&
          checks.fetch(:prepare_importmap, true)

        ok_verify = checks.fetch(:assets_dir, true) &&
          checks.fetch(:manifest_present, true) &&
          checks.fetch(:importmap_present, true) &&
          checks.fetch(:manifest_parse, true) &&
          checks.fetch(:importmap_parse, true) &&
          checks.fetch(:http_importmap, true) &&
          checks.fetch(:http_js, true) &&
          checks.fetch(:http_manifest, true)

        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8" />
            <title>Panda #{engine_name} – Dummy Asset Report</title>
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <style>
              body { margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; background: #020617; color: #e5e7eb; }
              .page { max-width: 1000px; margin: 2rem auto; padding: 2rem; background: #020617; }
              .card { border-radius: 1rem; border: 1px solid rgba(148,163,184,0.35); padding: 1.5rem; margin-bottom: 1.5rem; background: radial-gradient(circle at top left, rgba(56,189,248,0.12), transparent 55%), rgba(15,23,42,0.96); }
              .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem; }
              .pill { border-radius: 999px; font-size: 0.75rem; padding: 0.2rem 0.7rem; border: 1px solid rgba(148,163,184,0.45); text-transform: uppercase; letter-spacing: 0.04em; }
              .pill-ok { background: rgba(22,163,74,0.15); color: #4ade80; border-color: rgba(34,197,94,0.6); }
              .pill-fail { background: rgba(220,38,38,0.15); color: #fca5a5; border-color: rgba(248,113,113,0.6); }
              .pill-warn { background: rgba(234,179,8,0.12); color: #facc15; border-color: rgba(234,179,8,0.6); }

              h1 { font-size: 1.6rem; margin: 0 0 0.5rem; color: #e5e7eb; }
              h2 { font-size: 1.1rem; margin: 0; color: #e5e7eb; }
              p { margin: 0.3rem 0; color: #9ca3af; font-size: 0.9rem; }
              .muted { color: #6b7280; }

              .grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(220px,1fr)); gap: 1rem; margin-top: 0.75rem; }
              .metric { padding: 0.6rem 0.75rem; border-radius: 0.75rem; background: rgba(15,23,42,0.85); border: 1px solid rgba(31,41,55,0.9); }
              .metric-label { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.08em; color: #9ca3af; margin-bottom: 0.25rem; }
              .metric-value { font-size: 0.95rem; color: #e5e7eb; }

              table { border-collapse: collapse; width: 100%; font-size: 0.85rem; margin-top: 0.5rem; }
              th, td { text-align: left; padding: 0.35rem 0.4rem; border-bottom: 1px solid rgba(31,41,55,0.9); }
              th { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.08em; color: #9ca3af; }
              tr:last-child td { border-bottom: none; }

              .status-dot { width: 0.55rem; height: 0.55rem; border-radius: 999px; display: inline-block; margin-right: 0.3rem; }
              .dot-ok { background: #22c55e; box-shadow: 0 0 0 4px rgba(34,197,94,0.2); }
              .dot-fail { background: #f97373; box-shadow: 0 0 0 4px rgba(248,113,113,0.2); }
              .dot-skip { background: #eab308; box-shadow: 0 0 0 4px rgba(234,179,8,0.2); }

              code { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; font-size: 0.8rem; padding: 0.1rem 0.25rem; border-radius: 0.4rem; background: rgba(15,23,42,0.9); color: #e5e7eb; }
              .badge { border-radius: 999px; padding: 0.1rem 0.5rem; font-size: 0.7rem; border: 1px solid rgba(148,163,184,0.6); color: #9ca3af; }

              .err-list { margin-top: 0.5rem; padding-left: 1rem; }
              .err-list li { margin-bottom: 0.25rem; color: #fca5a5; }

              .js-source { font-size: 0.8rem; margin-top: 0.2rem; }
            </style>
          </head>
          <body>
            <div class="page">
              <div class="card">
                <div class="card-header">
                  <div>
                    <h1>Panda #{engine_name} – Dummy Asset Report</h1>
                    <p class="muted">Template v#{TEMPLATE_VERSION} · Generated at #{Time.now.utc.iso8601}</p>
                  </div>
                  <div>
                    <span class="pill #{ok_prepare ? "pill-ok" : "pill-fail"}">Prepare #{ok_prepare ? "OK" : "Failed"}</span>
                    <span class="pill #{ok_verify ? "pill-ok" : "pill-fail"}">Verify #{ok_verify ? "OK" : "Failed"}</span>
                  </div>
                </div>

                <div class="grid">
                  <div class="metric">
                    <div class="metric-label">Checks</div>
                    <div class="metric-value">
                      #{checks_summary_html}
                    </div>
                  </div>
                  <div class="metric">
                    <div class="metric-label">Manifest</div>
                    <div class="metric-value">
                      #{manifest.size} entries<br />
                      #{importmap.size} importmap imports
                    </div>
                  </div>
                  <div class="metric">
                    <div class="metric-label">Timings</div>
                    <div class="metric-value">
                      #{timings_summary_html}
                    </div>
                  </div>
                </div>

                #{errors_html}
              </div>

              <div class="card">
                <div class="card-header">
                  <h2>Checks</h2>
                  <span class="badge">Detail</span>
                </div>
                #{checks_table_html}
              </div>

              <div class="card">
                <div class="card-header">
                  <h2>JavaScript Resolution</h2>
                  <span class="badge">app/javascript + vendor/javascript</span>
                </div>
                #{js_resolution_html}
              </div>
            </div>
          </body>
          </html>
        HTML
      end

      def engine_name
        engine_key.to_s.split("_").map(&:capitalize).join(" ")
      end

      def checks_summary_html
        total = checks.size
        passed = checks.values.count(true)
        failed = checks.values.count(false)

        "#{passed}/#{total} passed · #{failed} failed"
      end

      def timings_summary_html
        return "No timings" if timings.empty?

        parts = []
        [:propshaft, :copy_js, :importmap, :http_importmap, :http_js, :http_manifest].each do |k|
          next unless timings[k]
          parts << "#{k}=#{timings[k]}s"
        end
        parts.join("<br />")
      end

      def errors_html
        return "" if errors.empty?

        items = errors.map { |e| "<li>#{ERB::Util.html_escape(e)}</li>" }.join
        <<~HTML
          <ul class="err-list">
            #{items}
          </ul>
        HTML
      end

      def checks_table_html
        rows = checks.map do |name, ok|
          label = name.to_s
          dot_class = ok ? "dot-ok" : "dot-fail"
          status = ok ? "OK" : "Failed"
          <<~ROW
            <tr>
              <td><span class="status-dot #{dot_class}"></span>#{ERB::Util.html_escape(label)}</td>
              <td>#{status}</td>
            </tr>
          ROW
        end.join

        <<~HTML
          <table>
            <thead>
              <tr>
                <th>Check</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              #{rows}
            </tbody>
          </table>
        HTML
      end

      def js_resolution_html
        return "<p class=\"muted\">No JS resolution information available.</p>" if js_resolution.empty?

        rows = js_resolution.map do |logical, info|
          sources = Array(info["sources"]).map { |p| "<code>#{ERB::Util.html_escape(p)}</code>" }.join("<br />")
          chosen = info["chosen"] ? "<code>#{ERB::Util.html_escape(info["chosen"])}</code>" : "<span class=\"muted\">n/a</span>"

          <<~ROW
            <tr>
              <td><code>#{ERB::Util.html_escape(logical)}</code></td>
              <td>#{chosen}</td>
              <td>#{sources}</td>
            </tr>
          ROW
        end.join

        <<~HTML
          <table>
            <thead>
              <tr>
                <th>Logical</th>
                <th>Chosen source</th>
                <th>All candidates</th>
              </tr>
            </thead>
            <tbody>
              #{rows}
            </tbody>
          </table>
        HTML
      end
    end
  end
end
