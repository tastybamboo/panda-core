# frozen_string_literal: true

# SimpleCov must be loaded before anything else
require "simplecov"
require "simplecov-json"
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::HTMLFormatter
])
SimpleCov.start

ENV["RAILS_ENV"] ||= "test"

require "rubygems"
require "bundler/setup"

# Load core and engine
require "panda/core"
require "panda/core/engine"

require "rails/all"

# Core-specific requires
require "propshaft"
require "stimulus-rails"
require "turbo-rails"
require "rails-controller-testing"

# Load dummy app environment BEFORE shared test infrastructure
require File.expand_path("../dummy/config/environment", __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Load RSpec/Rails BEFORE shared infrastructure to ensure correct paths
require "rspec/rails"

# Configure RSpec to use engine's spec directory, not dummy app's
# This must be done immediately after requiring rspec/rails
RSpec.configure do |config|
  # Override both default_path and pattern to use engine's spec directory
  engine_root = File.expand_path("..", __dir__)
  engine_spec_dir = File.join(engine_root, "spec")

  config.default_path = engine_spec_dir
  config.pattern = File.join(engine_spec_dir, "**/*_spec.rb")
end

# Now load shared test infrastructure (requires Rails app and RSpec to be loaded)
require "panda/core/testing/rails_helper"

Rails.application.eager_load!

# Ensures that the test database schema matches the current schema file.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Core-specific RSpec configuration
RSpec.configure do |config|
  # Configure fixtures path and enable fixtures
  config.fixture_paths = [File.expand_path("fixtures", __dir__)]
  config.use_transactional_fixtures = true

  # Load fixtures globally for all tests EXCEPT those that require users
  # panda_core_users are created programmatically
  fixture_files = Dir[File.expand_path("fixtures/*.yml", __dir__)].map do |f|
    File.basename(f, ".yml").to_sym
  end
  fixture_files.delete(:panda_core_users)
  config.global_fixtures = fixture_files unless ENV["SKIP_GLOBAL_FIXTURES"]

  # Core-specific asset checking in CI
  config.before(:suite) do
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n🔍 CI Environment Detected - Checking Core JavaScript Infrastructure..."

      # Verify compiled assets exist (find any panda-core assets)
      asset_dir = Rails.root.join("public/panda-core-assets")
      js_assets = Dir.glob(asset_dir.join("panda-core-*.js"))
      css_assets = Dir.glob(asset_dir.join("panda-core-*.css"))

      unless js_assets.any? && css_assets.any?
        puts "❌ CRITICAL: Compiled Core assets missing!"
        puts "   JavaScript files found: #{js_assets.count}"
        puts "   CSS files found: #{css_assets.count}"
        puts "   Looking in: #{asset_dir}"
        fail "Compiled assets not found - check asset compilation step"
      end

      puts "✅ Compiled Core assets found:"
      puts "   JavaScript: #{File.basename(js_assets.first)} (#{File.size(js_assets.first)} bytes)"
      puts "   CSS: #{File.basename(css_assets.first)} (#{File.size(css_assets.first)} bytes)"

      # Test basic Rails application responsiveness
      puts "\n🔍 Testing Rails application responsiveness..."
      begin
        require "net/http"
        require "capybara"

        # Try to make a basic HTTP request to test if Rails is responding
        if defined?(Capybara) && Capybara.current_session
          puts "   Capybara server: #{begin
            Capybara.current_session.server.base_url
          rescue
            "not available"
          end}"
        end

        # Check if database is accessible
        if defined?(ActiveRecord::Base)
          begin
            ActiveRecord::Base.connection.execute("SELECT 1")
            puts "   Database connection: ✅ OK"
          rescue => e
            puts "   Database connection: ❌ FAILED - #{e.message}"
          end
        end

        # Check if basic models can be loaded
        begin
          user_count = Panda::Core::User.count
          puts "   User model access: ✅ OK (#{user_count} users)"
        rescue => e
          puts "   User model access: ❌ FAILED - #{e.message}"
        end
      rescue => e
        puts "   Rails app check failed: #{e.message}"
      end
    end
  end
end
