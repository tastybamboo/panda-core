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
  spec.add_dependency "fx", "~> 0.9"
  spec.add_dependency "image_processing", "~> 1.2"
  spec.add_dependency "importmap-rails", "~> 2"
  spec.add_dependency "logidze", "~> 1.3"
  spec.add_dependency "lookbook", "~> 2.3"
  spec.add_dependency "omniauth", "~> 2.1"
  spec.add_dependency "omniauth-rails_csrf_protection", "~> 1.0"
  spec.add_dependency "pg", "~> 1.5"
  spec.add_dependency "propshaft", "~> 1.1"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "redis", "~> 5.3"
  spec.add_dependency "silencer", "~> 2.0"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "tailwindcss-rails", "~> 3"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "view_component", "~> 3"
end
