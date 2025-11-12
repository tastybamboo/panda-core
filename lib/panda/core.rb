# frozen_string_literal: true

require "rails"

module Panda
  module Core
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
