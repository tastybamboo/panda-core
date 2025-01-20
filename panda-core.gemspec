# frozen_string_literal: true

require_relative "lib/panda/core/version"

Gem::Specification.new do |spec|
  spec.name = "panda-core"
  spec.version = Panda::Core::VERSION
  spec.authors = ["Tasty Bamboo", "James Inman"]
  spec.email = ["bamboo@pandacms.io"]

  spec.summary = "Core libraries and development tools for Tasty Bamboo projects"
  spec.description = "Shared development tools, configurations, and utilities for Panda CMS and its related projects"
  spec.homepage = "https://github.com/tastybamboo/panda-core"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "{app,config,db,lib}/**/*",
    "LICENSE",
    "Rakefile",
    "README.md",
    "VERSION"
  ]

  # TODO: Some of these are optional dependencies or need moving to other gems?
  spec.add_dependency "activestorage-office-previewer", "~> 0.1"
  spec.add_dependency "awesome_nested_set", "~> 3.7"
  spec.add_dependency "aws-sdk-s3", "~> 1"
  spec.add_dependency "dry-configurable", "~> 1"
  spec.add_dependency "faraday", "~> 2"
  spec.add_dependency "faraday-multipart", "~> 1"
  spec.add_dependency "faraday-retry", "~> 2"
  spec.add_dependency "image_processing", "~> 1.2"
  spec.add_dependency "importmap-rails", "~> 2"
  spec.add_dependency "lookbook", "~> 2.3"
  spec.add_dependency "omniauth", "~> 2.1"
  spec.add_dependency "paper_trail", "~> 16"
  spec.add_dependency "propshaft", "~> 1.1"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "redis", "~> 5.3"
  spec.add_dependency "silencer", "~> 2.0"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "tailwindcss-rails", "~> 3"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "view_component", "~> 3"

  # OAuth providers - optional dependencies
  spec.add_dependency "omniauth-github", "~> 2.0"
  spec.add_dependency "omniauth-google-oauth2", "~> 1.2"
  spec.add_dependency "omniauth-microsoft_graph", "~> 2.0"
  spec.add_dependency "omniauth-rails_csrf_protection", "~> 1.0"

  # Database adapters - optional dependencies
  spec.add_dependency "pg", "~> 1.5"
  spec.add_dependency "sqlite3", ">= 2.4"

  # Development and testing dependencies
  spec.add_development_dependency "annotaterb"
  spec.add_development_dependency "better_errors"
  spec.add_development_dependency "binding_of_caller"
  spec.add_development_dependency "brakeman"
  spec.add_development_dependency "bullet"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "danger"
  spec.add_development_dependency "danger-reek"
  spec.add_development_dependency "danger-rubocop"
  spec.add_development_dependency "danger-simplecov_json"
  spec.add_development_dependency "danger-todoist"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "erb_lint"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "fasterer"
  spec.add_development_dependency "generator_spec"
  spec.add_development_dependency "listen"
  spec.add_development_dependency "lookbook", "~> 2"
  spec.add_development_dependency "puma"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-core", "~> 3.13"
  spec.add_development_dependency "rspec-github"
  spec.add_development_dependency "rspec-rails", "~> 7.1"
  spec.add_development_dependency "ruby-lsp"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-json"
  spec.add_development_dependency "simplecov-lcov"
  spec.add_development_dependency "simplecov_json_formatter"
  spec.add_development_dependency "simplecov_lcov_formatter"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "standard-rails"
  spec.add_development_dependency "stringio", ">= 3.1.2"
  spec.add_development_dependency "tty-box"
  spec.add_development_dependency "tty-screen"
  spec.add_development_dependency "yamllint"
  spec.add_development_dependency "yard-activerecord"
end
