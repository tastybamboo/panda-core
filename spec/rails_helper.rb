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
require "panda/core"

require "rails/all"

require File.expand_path("../dummy/config/environment", __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "propshaft"
require "stimulus-rails"
require "turbo-rails"
require "database_cleaner/active_record"
require "rails-controller-testing"
require "shoulda/matchers"
require "capybara"
require "capybara/rspec"
require "puma"

Rails.application.eager_load!

# Load all support files
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Configure fixtures
ActiveRecord::FixtureSet.context_class.send :include, ActiveSupport::Testing::TimeHelpers

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.include Panda::Core::Engine.routes.url_helpers
  config.include Rails.application.routes.url_helpers

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!

  config.before(:suite) do
    puts "Total examples to run: #{RSpec.world.example_count}\n"
  end

  # Use specific formatter for GitHub Actions
  if ENV["GITHUB_ACTIONS"] == "true"
    require "rspec/github"
    config.add_formatter RSpec::Github::Formatter
  end

  config.include Rails::Controller::Testing::TestProcess, type: :controller
  config.include Rails::Controller::Testing::TemplateAssertions, type: :controller
  config.include Rails::Controller::Testing::Integration, type: :controller

  # Improve test performance
  config.before(:suite) do
    # Reset column information for User model after migrations run
    # This is necessary because Rails caches column info when the model loads
    if defined?(Panda::Core::User)
      Panda::Core::User.connection.schema_cache.clear!
      Panda::Core::User.reset_column_information
    end
  end

  # Disable prepared statements for tests to avoid PostgreSQL caching issues
  config.before(:suite) do
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      ActiveRecord::Base.connection.unprepared_statement do
        # This block intentionally left empty
      end
      # Disable prepared statements globally for test environment
      ActiveRecord::Base.establish_connection(
        ActiveRecord::Base.connection_db_config.configuration_hash.merge(prepared_statements: false)
      )
    end
  end

  # Disable logging during tests
  config.before(:suite) do
    Rails.logger.level = Logger::ERROR
    ActiveRecord::Base.logger = nil if defined?(ActiveRecord)
    ActionController::Base.logger = nil if defined?(ActionController)
    ActionMailer::Base.logger = nil if defined?(ActionMailer)
  end

  # Suppress Rails command output during tests
  config.before(:each, type: :generator) do
    allow(Rails::Command).to receive(:invoke).and_return(true)
  end

  # Force all examples to run
  config.filter_run_including({})
  config.run_all_when_everything_filtered = true

  # Use transactions for all tests including system tests
  # System tests can use transactional fixtures because we're using
  # shared database connections (see capybara_setup.rb)
  config.use_transactional_fixtures = true

  # Infer an example group's spec type from the file location.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails and gems in backtraces.
  config.filter_rails_from_backtrace!
  # add, if needed: config.filter_gems_from_backtrace("gem name")

  # Allow using focus keywords "f... before a specific test"
  config.filter_run_when_matching :focus

  # Retry flaky tests automatically
  # This is especially useful for system tests that may have timing issues
  config.around(:each, :flaky) do |example|
    retry_count = example.metadata[:retry] || 3
    retry_count.times do |i|
      example.run
      break unless example.exception

      if i < retry_count - 1
        puts "\n[RETRY] Test failed, retrying... (attempt #{i + 2}/#{retry_count})"
        puts "[RETRY] Exception: #{example.exception.class.name}: #{example.exception.message[0..100]}"
        example.instance_variable_set(:@exception, nil)
        sleep 1 # Brief pause between retries
      end
    end
  end

  # Exclude EditorJS tests by default unless specifically requested
  config.filter_run_excluding :editorjs unless ENV["INCLUDE_EDITORJS"] == "true"

  # Log examples to allow using --only-failures and --next-failure
  config.example_status_persistence_file_path = "spec/examples.txt"

  # https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!

  # Use verbose output if only running one spec file
  config.default_formatter = "doc" if config.files_to_run.one?

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run: --seed 1234
  Kernel.srand config.seed
  config.order = :random

  # Use specific formatter for GitHub Actions
  RSpec.configure do |config|
    # Use the GitHub Annotations formatter for CI
    if ENV["GITHUB_ACTIONS"] == "true"
      require "rspec/github"
      config.add_formatter RSpec::Github::Formatter
    end
  end

  # Configure fixtures path and enable fixtures
  config.fixture_paths = [File.expand_path("fixtures", __dir__)]
  config.use_transactional_fixtures = true

  # Load fixtures globally for all tests EXCEPT those that require users
  # panda_core_users are created programatically
  # panda_cms_posts require users to exist first
  # Note: For system tests, fixtures are loaded explicitly in the around block below
  fixture_files = Dir[File.expand_path("fixtures/*.yml", __dir__)].map do |f|
    File.basename(f, ".yml").to_sym
  end
  fixture_files.delete(:panda_core_users)
  config.global_fixtures = fixture_files unless ENV["SKIP_GLOBAL_FIXTURES"]

  if defined?(Bullet) && Bullet.enable?
    config.before(:each) do
      Bullet.start_request
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  OmniAuth.config.test_mode = true

  config.before(:suite) do
    # Allow DATABASE_URL in CI environment
    if ENV["DATABASE_URL"]
      DatabaseCleaner.allow_remote_database_url = true
    end

    DatabaseCleaner.clean_with :truncation

    # Global check for JavaScript loading issues in CI
    # This will fail fast if we detect systematic JavaScript problems
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n🔍 CI Environment Detected - Checking JavaScript Infrastructure..."

      # Verify compiled assets exist (find any panda-core assets)
      asset_dir = Rails.root.join("public/panda-core-assets")
      js_assets = Dir.glob(asset_dir.join("panda-core-*.js"))
      css_assets = Dir.glob(asset_dir.join("panda-core-*.css"))

      unless js_assets.any? && css_assets.any?
        puts "❌ CRITICAL: Compiled assets missing!"
        puts "   JavaScript files found: #{js_assets.count}"
        puts "   CSS files found: #{css_assets.count}"
        puts "   Looking in: #{asset_dir}"
        fail "Compiled assets not found - check asset compilation step"
      end

      puts "✅ Compiled assets found:"
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
