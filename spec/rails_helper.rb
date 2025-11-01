# Silence Thor deprecation warnings
ENV["THOR_SILENCE_DEPRECATION"] = "1"

# Set Rails environment FIRST before any requires
ENV["RAILS_ENV"] = "test"

require "simplecov"
require "simplecov-json"
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start

require "bundler/setup"

# Add this line before requiring the gem
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative "../lib/panda/core"

require File.expand_path("../dummy/config/environment", __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "rails-controller-testing"
require "rails/generators/test_case"

# Add additional requires below this line. Rails is not loaded until this point!
require "shoulda/matchers"
require "capybara"
require "capybara/rspec"
require "puma"
require "generator_spec"

# Load all support files
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # Force all examples to run and set proper types
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
    meta[:type] = case meta[:file_path]
    when %r{spec/generators/} then :generator
    when %r{spec/lib/} then :lib
    else meta[:type]
    end
  end

  # Only run our specific specs
  config.pattern = "{spec/lib/panda/core/configuration_spec.rb,spec/generators/panda/core/install_generator_spec.rb,spec/generators/panda/core/templates_generator_spec.rb,spec/models/**/*_spec.rb,spec/controllers/**/*_spec.rb,spec/components/**/*_spec.rb,spec/requests/**/*_spec.rb,spec/system/**/*_spec.rb}"

  # Exclude dummy app specs
  config.exclude_pattern = "spec/dummy/**/*_spec.rb"

  # Debug which files are being loaded
  config.before(:suite) do
    puts "\nSpec files being loaded:"
    puts RSpec.configuration.files_to_run.map { |f| File.basename(f) }
    puts "\nExample groups being run:"
    puts RSpec.world.example_groups.map { |g|
      examples = g.children.flat_map(&:examples).map(&:description)
      [g.description, examples]
    }
    puts "\nTotal examples to run: #{RSpec.world.example_count}"
    puts "\n"
  end

  # URL helpers in tests would be nice to use
  config.include Rails.application.routes.url_helpers

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!

  # Use specific formatter for GitHub Actions
  if ENV["GITHUB_ACTIONS"] == "true"
    require "rspec/github"
    config.add_formatter RSpec::Github::Formatter
  end

  config.include Capybara::RSpecMatchers, type: :view_component
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  config.include Rails::Generators::Testing::Assertions, type: :generator
  config.include FileUtils, type: :generator
  config.include Rails::Controller::Testing::TestProcess, type: :controller
  config.include Rails::Controller::Testing::TemplateAssertions, type: :controller
  config.include Rails::Controller::Testing::Integration, type: :controller

  # Set up temporary directory for generator tests
  config.before(:each, type: :generator) do
    FileUtils.rm_rf(Rails.root.join("tmp/generators"))
    FileUtils.mkdir_p(Rails.root.join("tmp/generators"))
  end

  config.after(:each, type: :generator) do
    FileUtils.rm_rf(Rails.root.join("tmp/generators"))
  end

  # Improve test performance
  config.before(:suite) do
    Rails.application.eager_load!

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
end
