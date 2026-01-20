# frozen_string_literal: true

# Shared RSpec configuration for all Panda gems
# This file provides common test infrastructure that can be extended by individual gems
#
# IMPORTANT: This file should be required AFTER the dummy app is loaded
# Individual gem rails_helper files should:
# 1. Set up SimpleCov
# 2. Require panda/core and the dummy app
# 3. Require this file
# 4. Load gem-specific support files

# Require common test gems (assumes Rails and RSpec/Rails are already loaded by gem's rails_helper)
require "database_cleaner/active_record"
require "shoulda/matchers"
require "capybara"
require "capybara/rspec"
require "puma"
require "action_controller/test_case"
require "view_component/test_helpers"
require_relative "view_component_test_controller"

# Configure ViewComponent to use our test controller
if defined?(ViewComponent) && Rails.application && Rails.application.config.respond_to?(:view_component)
  Rails.application.config.view_component.test_controller = "ViewComponentTestController"
end

# Configure fixtures
ActiveRecord::FixtureSet.context_class.send :include, ActiveSupport::Testing::TimeHelpers

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Load all support files from panda-core
# Files are now in lib/panda/core/testing/support/ to be included in the published gem
support_path = File.expand_path("../support", __FILE__)

# Load system test infrastructure first (Capybara, Cuprite, helpers)
system_test_files = Dir[File.join(support_path, "system/**/*.rb")].sort
system_test_files.each { |f| require f }

# Load other support files
other_support_files = Dir[File.join(support_path, "**/*.rb")].sort.reject { |f| f.include?("/system/") }
other_support_files.each { |f| require f }

RSpec.configure do |config|
  # Include panda-core route helpers by default
  config.include Panda::Core::Engine.routes.url_helpers if defined?(Panda::Core::Engine)
  config.include Rails.application.routes.url_helpers

  # Standard RSpec configuration
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!

  # Print total example count before running
  config.before(:suite) do
    puts "Total examples to run: #{RSpec.world.example_count}\n"
  end

  # Use specific formatter for GitHub Actions
  if ENV["GITHUB_ACTIONS"] == "true"
    require "rspec/github"
    config.add_formatter RSpec::Github::Formatter
    # Also add documentation formatter for colored real-time output in CI logs,
    # but avoid double-printing when one is already configured (e.g. via CLI).
    unless config.formatters.any? { |formatter| formatter.is_a?(RSpec::Core::Formatters::DocumentationFormatter) }
      config.add_formatter RSpec::Core::Formatters::DocumentationFormatter, $stdout
    end
  end

  # Controller testing support (if rails-controller-testing is available)
  if defined?(Rails::Controller::Testing)
    config.include Rails::Controller::Testing::TestProcess, type: :controller
    config.include Rails::Controller::Testing::TemplateAssertions, type: :controller
    config.include Rails::Controller::Testing::Integration, type: :controller
  end

  # ViewComponent testing support (if view_component is available)
  if defined?(ViewComponent::TestHelpers)
    config.include ViewComponent::TestHelpers, type: :component
    config.include Capybara::RSpecMatchers, type: :component
    config.include Panda::Core::AssetHelper, type: :component
  end

  # Reset column information before suite
  config.before(:suite) do
    if defined?(Panda::Core::User)
      Panda::Core::User.connection.schema_cache.clear!
      Panda::Core::User.reset_column_information
    end
  end

  # Disable prepared statements for PostgreSQL tests to avoid caching issues
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

  # Force all examples to run
  config.filter_run_including({})
  config.run_all_when_everything_filtered = true

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

  # Note: Fixture configuration is gem-specific and should be done in each gem's rails_helper.rb
  # This includes config.fixture_paths and config.global_fixtures

  # Bullet configuration (if available)
  if defined?(Bullet) && Bullet.enable?
    config.before(:each) do
      Bullet.start_request
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  # OmniAuth test mode
  OmniAuth.config.test_mode = true if defined?(OmniAuth)

  # Stub Panda Core helpers for component tests
  config.before(:each, type: :component) do
    if defined?(ViewComponent::TestHelpers)
      allow_any_instance_of(ActionView::Base).to receive(:panda_core_stylesheet).and_return("")
      allow_any_instance_of(ActionView::Base).to receive(:panda_core_javascript).and_return("")
      allow_any_instance_of(ActionView::Base).to receive(:csrf_meta_tags).and_return("")
      allow_any_instance_of(ActionView::Base).to receive(:csp_meta_tag).and_return("")
      allow_any_instance_of(ActionView::Base).to receive(:controller).and_return(
        double(
          class: double(name: "Test"),
          protect_against_forgery?: false,
          content_security_policy?: false
        )
      )

      # Stub link_to and button_to to avoid routing complexity in component tests
      allow_any_instance_of(ActionView::Base).to receive(:link_to) do |*args, &block|
        href = args[0].is_a?(Hash) ? "#" : args[0]
        options = args.find { |a| a.is_a?(Hash) } || {}
        css_class = options[:class] || ""
        content = block ? block.call : args[1] || href
        "<a href=\"#{href}\" class=\"#{css_class}\">#{content}</a>".html_safe
      end

      allow_any_instance_of(ActionView::Base).to receive(:button_to) do |*args, &block|
        args[0]
        options = args[1] || {}
        css_class = options[:class] || ""
        content = block ? block.call : "Button"
        id_attr = options[:id] ? " id=\"#{options[:id]}\"" : ""
        "<button class=\"#{css_class}\"#{id_attr}>#{content}</button>".html_safe
      end

      # Stub panda_core routes to return simple paths
      panda_core_routes = double("panda_core_routes")
      allow(panda_core_routes).to receive(:admin_logout_path).and_return("/admin/logout")
      allow(panda_core_routes).to receive(:admin_my_profile_path).and_return("/admin/my_profile")
      allow_any_instance_of(ActionView::Base).to receive(:panda_core).and_return(panda_core_routes)

      # Stub current_user
      mock_user = double(
        "User",
        name: "Test User",
        avatar: double(attached?: false),
        image_url: ""
      )
      allow_any_instance_of(ActionView::Base).to receive(:current_user).and_return(mock_user)

      # Stub main_app routes
      main_app_routes = double(url_for: "/test")
      allow_any_instance_of(ActionView::Base).to receive(:main_app).and_return(main_app_routes)
    end
  end

  # DatabaseCleaner configuration
  config.around(:each) do |example|
    DatabaseCleaner.strategy = (example.metadata[:type] == :system) ? :truncation : :transaction
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.before(:each, type: :system) do
    driven_by :panda_cuprite
  end

  config.use_transactional_fixtures = false

  config.before(:suite) do
    # Allow DATABASE_URL in CI environment
    if ENV["DATABASE_URL"] &&
        ENV["SKIP_DB_CLEAN_WITH_DATABASE_URL"].nil? &&
        ENV["ACT"] != "true"
      DatabaseCleaner.allow_remote_database_url = true
      DatabaseCleaner.clean_with(:truncation)
    end

    # Hook for gems to add custom suite setup
    # Gems can define Panda::Testing.before_suite_hook and it will be called here
    if defined?(Panda::Testing) && Panda::Testing.respond_to?(:before_suite_hook)
      Panda::Testing.before_suite_hook
    end
  end
end
