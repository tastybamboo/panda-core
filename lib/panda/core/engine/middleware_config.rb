# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Middleware configuration for static assets
      module MiddlewareConfig
        extend ActiveSupport::Concern

        included do
          # Make files in public available to the main app (e.g. /panda-core-assets/panda-logo.png)
          config.middleware.use Rack::Static,
            urls: ["/panda-core-assets"],
            root: Panda::Core::Engine.root.join("public"),
            header_rules: [
              # Disable caching in development for instant CSS updates
              [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000"}]
            ]

          # Make JavaScript files available for importmap
          # Serve from app/javascript with proper MIME types
          config.middleware.use Rack::Static,
            urls: ["/panda", "/panda/core"],
            root: Panda::Core::Engine.root.join("app/javascript"),
            header_rules: [
              [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000",
                      "Content-Type" => "text/javascript; charset=utf-8"}]
            ]
        end
      end
    end
  end
end
