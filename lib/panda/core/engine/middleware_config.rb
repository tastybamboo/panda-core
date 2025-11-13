# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Middleware configuration for static assets
      # Note: Actual middleware is registered in engine.rb initializer
      # This module is kept for organizational purposes
      module MiddlewareConfig
        extend ActiveSupport::Concern

        # Middleware configuration moved to engine.rb initializer
        # See lib/panda/core/engine.rb - initializer "panda.core.static_assets"
      end
    end
  end
end
