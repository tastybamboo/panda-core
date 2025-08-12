# frozen_string_literal: true

module Panda
  module Core
    module Testing
      module RSpecConfig
        def self.configure(config)
          # Add common RSpec configurations
          config.expect_with :rspec do |expectations|
            expectations.include_chain_clauses_in_custom_matcher_descriptions = true
          end

          config.mock_with :rspec do |mocks|
            mocks.verify_partial_doubles = true
          end

          config.shared_context_metadata_behavior = :apply_to_host_groups
          config.filter_run_when_matching :focus
          config.example_status_persistence_file_path = "spec/examples.txt"
          config.disable_monkey_patching!

          if config.files_to_run.one?
            config.default_formatter = "doc"
          end

          config.order = :random
          Kernel.srand config.seed

          # Database cleaner setup
          if defined?(DatabaseCleaner)
            config.before(:suite) do
              DatabaseCleaner.strategy = :transaction
              DatabaseCleaner.clean_with(:truncation)
            end

            config.around(:each) do |example|
              DatabaseCleaner.cleaning do
                example.run
              end
            end
          end

          # OmniAuth test mode
          if defined?(OmniAuth)
            config.before(:each) do
              OmniAuth.config.test_mode = true
            end

            config.after(:each) do
              OmniAuth.config.mock_auth.clear
            end
          end
        end

        # Common matchers for Panda gems
        def self.setup_matchers
          RSpec::Matchers.define :have_breadcrumb do |expected|
            match do |page|
              page.has_css?(".breadcrumb", text: expected)
            end
          end

          RSpec::Matchers.define :have_flash_message do |type, message|
            match do |page|
              page.has_css?(".flash-message.flash-#{type}", text: message)
            end
          end
        end
      end
    end
  end
end
