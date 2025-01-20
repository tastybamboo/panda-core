# Silence Thor deprecation warnings
ENV["THOR_SILENCE_DEPRECATION"] = "1"

require "simplecov"
require "simplecov-json"
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start

require "bundler/setup"

# Add this line before requiring the gem
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative "../lib/panda/core"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "rails/generators/test_case"

# Add additional requires below this line. Rails is not loaded until this point!
require "shoulda/matchers"
require "capybara"
require "capybara/rspec"
require "view_component/test_helpers"
require "faker"
require "puma"
require "factory_bot_rails"

# Load all support files
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # Configure RSpec to find specs in the correct directories
  config.pattern = "spec/{generators,lib}/**/*_spec.rb"

  # URL helpers in tests would be nice to use
  config.include Rails.application.routes.url_helpers

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  # Use specific formatter for GitHub Actions
  if ENV["GITHUB_ACTIONS"] == "true"
    require "rspec/github"
    config.add_formatter RSpec::Github::Formatter
  end

  config.include ViewComponent::TestHelpers, type: :view_component
  config.include Capybara::RSpecMatchers, type: :view_component
  config.include FactoryBot::Syntax::Methods
  config.include Rails::Generators::Testing::Assertions, type: :generator
  config.include FileUtils, type: :generator

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

  # Debug which files are being loaded
  config.before(:suite) do
    puts "\nSpec files being loaded:"
    puts RSpec.configuration.files_to_run.map { |f| File.basename(f) }
    puts "\n"
  end
end
