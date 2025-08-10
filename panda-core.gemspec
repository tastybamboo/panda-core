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

  spec.add_dependency "importmap-rails"
  spec.add_dependency "omniauth"
  spec.add_dependency "omniauth-rails_csrf_protection"
  spec.add_dependency "omniauth-google-oauth2"
  spec.add_dependency "omniauth-github"
  spec.add_dependency "omniauth-microsoft_graph"
  spec.add_dependency "propshaft"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "stimulus-rails"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "view_component"

  spec.add_development_dependency "pg"

  # Testing
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "database_cleaner-active_record"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-json"

  # Linting & Code Quality
  spec.add_development_dependency "standard"
  spec.add_development_dependency "brakeman"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "yamllint"

  # Development Tools
  spec.add_development_dependency "debug"
  spec.add_development_dependency "pry-rails"
end
