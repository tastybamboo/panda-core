# frozen_string_literal: true

require "rails"

module Panda
  module Core
    def self.root
      File.expand_path("../..", __FILE__)
    end
  end
end

require_relative "core/version"
require_relative "core/configuration"
require_relative "core/asset_loader"
require_relative "core/engine" if defined?(Rails)
