# frozen_string_literal: true

require "erb"

module Panda
  module Core
    module Testing
      module Assets
        module Report
          module_function

          def write(dummy_root:, engine_name:, result:)
            tmp_dir = File.join(dummy_root, "tmp")
            FileUtils.mkdir_p(tmp_dir)
            path = File.join(tmp_dir, "panda_assets_report.html")

            html = render_html(engine_name, result)
            File.write(path, html)

            path
          rescue => e
            warn "⚠️ Could not write HTML report: #{e.message}"
            nil
          end

          def render_html(engine_name, result)
            template = <<~HTML
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="UTF-8">
                <title><%= engine_name %> Asset Verification Report</title>
                <style>
                  body { font-family: system-ui, -apple-system, sans-serif; margin: 2rem; background: #f7fafc; color: #1a202c; }
                  h1 { font-size: 1.8rem; margin-bottom: 0.5rem; }
                  h2 { font-size: 1.4rem; margin-top: 2rem; }
                  .status-ok { color: #16a34a; }
                  .status-fail { color: #dc2626; }
                  .card { background: white; border-radius: 0.5rem; padding: 1rem 1.5rem; margin-top: 1rem; box-shadow: 0 1px 3px rgba(15, 23, 42, 0.1); }
                  table { width: 100%; border-collapse: collapse; margin-top: 0.5rem; }
                  th, td { padding: 0.4rem 0.6rem; border-bottom: 1px solid #e5e7eb; font-size: 0.9rem; text-align: left; }
                  th { background: #f3f4f6; font-weight: 600; }
                  .tag { display: inline-block; padding: 0.1rem 0.5rem; border-radius: 999px; font-size: 0.75rem; }
                  .tag-ok { background: #dcfce7; color: #166534; }
                  .tag-fail { background: #fee2e2; color: #991b1b; }
                  .muted { color: #6b7280; font-size: 0.85rem; }
                  pre { background: #0f172a; color: #e5e7eb; padding: 0.75rem; border-radius: 0.5rem; overflow: auto; font-size: 0.8rem; }
                </style>
              </head>
              <body>
                <h1><%= engine_name %> Asset Verification</h1>
                <p class="<%= result[:ok] ? 'status-ok' : 'status-fail' %>">
                  <strong>Status:</strong> <%= result[:ok] ? '✅ Success' : '❌ Failed' %>
                </p>

                <div class="card">
                  <h2>Timing</h2>
                  <table>
                    <thead>
                      <tr><th>Phase</th><th>Duration</th></tr>
                    </thead>
                    <tbody>
                      <% result[:timings].each do |k, v| %>
                        <tr>
                          <td><%= k.to_s.tr('_', ' ').capitalize %></td>
                          <td><%= format('%.2fs', v) %></td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>

                <div class="card">
                  <h2>Checks</h2>
                  <table>
                    <thead>
                      <tr><th>Check</th><th>Status</th></tr>
                    </thead>
                    <tbody>
                      <% result[:checks].each do |check| %>
                        <tr>
                          <td><%= check[:name] %></td>
                          <td>
                            <% if check[:ok] %>
                              <span class="tag tag-ok">OK</span>
                            <% else %>
                              <span class="tag tag-fail">FAIL</span>
                            <% end %>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>

                <% if result[:errors].any? %>
                  <div class="card">
                    <h2>Errors</h2>
                    <% result[:errors].each do |err| %>
                      <p><strong><%= err[:where] %>:</strong> <%= err[:message] %></p>
                    <% end %>
                  </div>
                <% end %>

                <% if result[:http_failures].any? %>
                  <div class="card">
                    <h2>HTTP Failures</h2>
                    <table>
                      <thead>
                        <tr><th>Type</th><th>Path</th><th>Detail</th></tr>
                      </thead>
                      <tbody>
                        <% result[:http_failures].each do |hit| %>
                          <tr>
                            <td><%= hit[:category] %></td>
                            <td><code><%= hit[:path] %></code></td>
                            <td><%= hit[:detail] %></td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                <% end %>

                <div class="card">
                  <h2>Environment</h2>
                  <p class="muted">
                    Ruby: <%= RUBY_DESCRIPTION %><br>
                    Rails: <%= defined?(Rails) ? Rails.version : 'n/a' %><br>
                    RAILS_ENV: <%= ENV['RAILS_ENV'] || 'n/a' %>
                  </p>
                </div>
              </body>
              </html>
            HTML

            ERB.new(template).result(binding)
          end
        end
      end
    end
  end
end
