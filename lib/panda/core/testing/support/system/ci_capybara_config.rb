require "capybara/cuprite"

Capybara.default_max_wait_time = ENV.fetch("CAPYBARA_MAX_WAIT_TIME", "5").to_i
Capybara.raise_server_errors = true

# Server selection (overridable via env)
server_name = ENV.fetch("CAPYBARA_SERVER", "puma").to_sym
Capybara.server = server_name
Capybara.server_host = ENV.fetch("CAPYBARA_SERVER_HOST", "127.0.0.1")
# Allow dynamic port by leaving blank
port_env = ENV["CAPYBARA_PORT"]
Capybara.server_port = (port_env && !port_env.empty?) ? port_env.to_i : nil
app_host_env = ENV["CAPYBARA_APP_HOST"]
Capybara.app_host = app_host_env unless app_host_env.to_s.empty?
Capybara.always_include_port = !Capybara.app_host.nil?
Capybara.default_driver = :rack_test

HEADLESS = !(ENV["HEADFUL"] == "true")

def panda_core_cuprite_options(window_size:)
  ci_default_timeout = 10
  ci_default_process_timeout = 30
  default_timeout = ENV["CI"] ? ci_default_timeout : 5
  default_process_timeout = ENV["CI"] ? ci_default_process_timeout : 10

  cuprite_timeout = ENV["CUPRITE_TIMEOUT"]&.to_i ||
    ENV["FERRUM_TIMEOUT"]&.to_i ||
    default_timeout

  process_timeout_value = ENV["CUPRITE_PROCESS_TIMEOUT"]&.to_i ||
    ENV["FERRUM_PROCESS_TIMEOUT"]&.to_i ||
    default_process_timeout

  browser_path = ENV["BROWSER_PATH"] ||
    ["/usr/bin/chromium", "/usr/bin/chromium-browser", "/usr/bin/google-chrome"].find { |p| File.exist?(p) }

  {
    window_size: window_size,
    headless: HEADLESS,
    browser_path: browser_path,
    timeout: cuprite_timeout,
    process_timeout: process_timeout_value,
    js_errors: true,
    browser_options: {
      "disable-gpu" => nil,
      "disable-dev-shm-usage" => nil,
      "no-sandbox" => nil,
      "disable-setuid-sandbox" => nil,
      "remote-debugging-port" => "0"
    },
    screenshot_options: {
      full: true,
      quality: 85
    }
  }
end

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, **panda_core_cuprite_options(window_size: [1400, 900]))
end

Capybara.register_driver(:cuprite_mobile) do |app|
  Capybara::Cuprite::Driver.new(app, **panda_core_cuprite_options(window_size: [375, 667]))
end

Capybara.javascript_driver = :cuprite
