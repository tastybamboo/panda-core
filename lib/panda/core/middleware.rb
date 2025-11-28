# frozen_string_literal: true

module Panda
  module Core
    module Middleware
      # Rails 8 safe middleware insertion:
      #
      # Use app.config.app_middleware (Rack::Builder-compatible)
      # Not app.config.middleware (MiddlewareStackProxy)
      #
      def self.use(app, klass, *args, &block)
        app.config.app_middleware.use(klass, *args, &block)
      end
    end
  end
end
