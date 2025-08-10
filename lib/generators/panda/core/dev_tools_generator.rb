# frozen_string_literal: true

require "rails/generators"

module Panda
  module Core
    module Generators
      class DevToolsGenerator < Rails::Generators::Base
        source_root File.expand_path("dev_tools/templates", __dir__)

        desc "Set up or update Panda Core development tools in your gem/application"

        class_option :force, type: :boolean, default: false,
          desc: "Overwrite existing files"
        class_option :skip_dependencies, type: :boolean, default: false,
          desc: "Skip adding dependencies to Gemfile"

        VERSION_FILE = ".panda-dev-tools-version"
        CURRENT_VERSION = "1.0.0"

        def check_for_updates
          if File.exist?(VERSION_FILE)
            installed_version = File.read(VERSION_FILE).strip
            if installed_version != CURRENT_VERSION
              say "Updating Panda Core dev tools from #{installed_version} to #{CURRENT_VERSION}", :yellow
              @updating = true
            else
              say "Panda Core dev tools are up to date (#{CURRENT_VERSION})", :green
              unless options[:force]
                say "Use --force to reinstall anyway"
                nil
              end
            end
          else
            say "Installing Panda Core dev tools #{CURRENT_VERSION}", :green
            @updating = false
          end
        end

        def copy_linting_configs
          say "Copying linting configurations..."
          copy_file ".standard.yml", force: options[:force] || @updating
          copy_file ".yamllint", force: options[:force] || @updating
          copy_file ".rspec", force: options[:force] || @updating
          copy_file "lefthook.yml", force: options[:force] || @updating
        end

        def copy_github_workflows
          say "Copying GitHub Actions workflows..."
          directory ".github", ".github", force: options[:force] || @updating
        end

        def create_version_file
          create_file VERSION_FILE, CURRENT_VERSION, force: true
        end

        def add_development_dependencies
          say "Adding development dependencies to gemspec..."

          if File.exist?("Gemfile")
            append_to_file "Gemfile" do
              <<~RUBY
                
                group :development, :test do
                  # Panda Core development tools
                  gem "standard"
                  gem "brakeman"
                  gem "bundler-audit"
                  gem "yamllint"
                end
              RUBY
            end
          end
        end

        def create_spec_helper
          say "Creating spec helper with Panda Core testing configuration..."

          create_file "spec/support/panda_core_helpers.rb" do
            <<~RUBY
              # frozen_string_literal: true
              
              require 'panda/core/testing/rspec_config'
              require 'panda/core/testing/omniauth_helpers'
              require 'panda/core/testing/capybara_config'
              
              RSpec.configure do |config|
                # Apply Panda Core RSpec configuration
                Panda::Core::Testing::RSpecConfig.configure(config)
                Panda::Core::Testing::RSpecConfig.setup_matchers
                
                # Configure Capybara
                Panda::Core::Testing::CapybaraConfig.configure
                
                # Include helpers
                config.include Panda::Core::Testing::OmniAuthHelpers, type: :system
                config.include Panda::Core::Testing::CapybaraConfig::Helpers, type: :system
              end
            RUBY
          end
        end

        def add_rake_tasks
          say "Adding Panda Core rake tasks..."

          append_to_file "Rakefile" do
            <<~RUBY
              
              # Panda Core development tasks
              namespace :panda do
                desc "Run all linters"
                task :lint do
                  sh "bundle exec standardrb"
                  sh "yamllint -c .yamllint ."
                end
                
                desc "Run security checks"
                task :security do
                  sh "bundle exec brakeman --quiet"
                  sh "bundle exec bundle-audit --update"
                end
                
                desc "Run all quality checks"
                task quality: [:lint, :security]
              end
            RUBY
          end
        end

        def display_instructions
          say "\n✅ Panda Core development tools have been set up!", :green
          say "\nNext steps:"
          say "  1. Run 'bundle install' to install new dependencies"
          say "  2. Run 'bundle exec rake panda:quality' to check code quality"
          say "  3. Customize .github/workflows for your gem's needs"
          say "  4. Add 'require' statements to your spec_helper.rb or rails_helper.rb:"
          say "     require 'support/panda_core_helpers'"
          say "\nFor more information, see: docs/development_tools.md"
        end
      end
    end
  end
end
