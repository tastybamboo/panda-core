# frozen_string_literal: true

require "rails"
# require "active_support/core_ext/module/attribute_accessors"

# Load inflections early so they're available for generators
# This must happen before any code tries to camelize/classify strings
# containing "cms", "seo", "ai", or "uuid"
require "active_support/inflector"
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "CMS"
  inflect.acronym "SEO"
  inflect.acronym "AI"
  inflect.acronym "UUID"
end

module Panda
  module Core
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

require_relative "core/version"
require_relative "core/configuration"
require_relative "core/asset_loader"
require_relative "core/debug"
require_relative "core/services/base_service"
require_relative "core/shared/inflections_config"
require_relative "core/shared/generator_config"
require_relative "core/engine" if defined?(Rails)
