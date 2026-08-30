require_relative "boot"

require "rails/all"
require "rails/generators"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults Rails::VERSION::STRING.to_f

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't use API-only mode to support ViewComponent components
    config.api_only = false

    # Host apps differ on primary key type, and that decides what Rails' own
    # Active Storage / Action Text migrations build (they read
    # Rails.configuration.generators at migration time). bin/verify-migration-paths
    # migrates the dummy app both ways so panda-core's migrations are exercised
    # against a bigint host app and a uuid host app. See docs/migration-paths.md.
    if ENV["PANDA_CORE_UUID_PRIMARY_KEYS"].present?
      config.generators do |g|
        g.orm :active_record, primary_key_type: :uuid
      end
    end
  end
end
