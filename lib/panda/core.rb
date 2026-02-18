# frozen_string_literal: true

require "rails"
# require "active_support/core_ext/module/attribute_accessors"

# Load inflections early so they're available for generators
require "active_support/inflector"

module Panda
  module Core
    # Single source of truth for acronyms used across all Panda gems.
    # Referenced by Shared::InflectionsConfig (engine initializer) and
    # applied eagerly below for generator/CLI contexts.
    ACRONYMS = %w[CMS SEO AI URL UUID].freeze

    # Session key for storing authenticated Panda Core admin user ID
    # Namespaced to avoid conflicts with host application user sessions
    ADMIN_SESSION_KEY = :panda_core_user_id

    def self.root
      File.expand_path("../..", __FILE__)
    end

    # Store the engine's importmap separately from the app's
    mattr_accessor :importmap
  end
end

# Apply acronyms eagerly for generators and CLI contexts
ActiveSupport::Inflector.inflections(:en) do |inflect|
  Panda::Core::ACRONYMS.each { |acronym| inflect.acronym acronym }
end

require_relative "core/version"
require_relative "core/configuration"
require_relative "core/navigation_registry"
require_relative "core/widget_registry"
require_relative "core/asset_loader"
require_relative "core/debug"
require_relative "core/services/base_service"
require_relative "core/shared/inflections_config"
require_relative "core/shared/generator_config"
require_relative "core/engine" if defined?(Rails)
