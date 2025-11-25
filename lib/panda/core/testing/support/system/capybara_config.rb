# # frozen_string_literal: true

# # Shared Capybara configuration for all Panda gems
# # This provides standard Capybara setup with sensible defaults

# # We don't want to hang around for too long for processes at the moment
# Capybara.default_max_wait_time = ENV["CAPYBARA_MAX_WAIT_TIME"].present? ? ENV["CAPYBARA_MAX_WAIT_TIME"].to_i : 2

# # Normalize whitespaces when using `has_text?` and similar matchers,
# # i.e., ignore newlines, trailing spaces, etc.
# # That makes tests less dependent on slight UI changes.
# Capybara.default_normalize_ws = true

# # Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# # It could be useful to be able to configure this path from the outside (e.g., on CI).
# Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

# # Disable animation so we're not waiting for it
# Capybara.disable_animation = true

# # See SystemTestHelpers#take_screenshot
# # This allows us to track which session was last used for proper screenshot naming
# Capybara.singleton_class.prepend(Module.new do
#   attr_accessor :last_used_session

#   def using_session(name, &block)
#     self.last_used_session = name
#     super
#   ensure
#     self.last_used_session = nil
#   end
# end)

# # Configure server host and port
# # This is loaded for all environments
# # → you do not want fixed ports there
# Capybara.server_host = "127.0.0.1"
# Capybara.server_port = ENV["CAPYBARA_PORT"]&.to_i # Let Capybara choose if not specified

# # Configure Puma server with explicit options
# # Use single-threaded mode to share database connection with tests
# Capybara.register_server :puma do |app, port, host|
#   require "rack/handler/puma"
#   Rack::Handler::Puma.run(app, Port: port, Host: host, Silent: true, Threads: "1:1")
# end
# Capybara.server = :puma

# # Do not set app_host here - let Capybara determine it from the server
# # This avoids conflicts between what's configured and what's actually running

# # RSpec configuration for Capybara
# RSpec.configure do |config|
#   # Save screenshots on system test failures
#   config.after(:each, type: :system) do |example|
#     if example.exception
#       timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
#       "tmp/capybara/failures/#{example.full_description.parameterize}_#{timestamp}"

#       # Screenshots are saved automatically by Capybara, but we could save additional artifacts here
#       # save_page("#{filename_base}.html")
#       # save_screenshot("#{filename_base}.png", full: true)
#     end
#   end
# end
