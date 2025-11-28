# frozen_string_literal: true

require "rails"
require "omniauth"

require "panda/core/middleware"
require "panda/core/module_registry"

# Shared engine mixins
require_relative "shared/inflections_config"
require_relative "shared/generator_config"

# Engine mixins
require_relative "engine/autoload_config"
require_relative "engine/importmap_config"
require_relative "engine/omniauth_config"
require_relative "engine/phlex_config"
require_relative "engine/admin_controller_config"

module Panda
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Core

      #
      # Include shared behaviours
      #
      include Shared::InflectionsConfig
      include Shared::GeneratorConfig

      #
      # Include engine-level concerns
      #
      include AutoloadConfig
      include ImportmapConfig
      include OmniauthConfig
      include PhlexConfig
      include AdminControllerConfig

      #
      # Misc configuration point
      #
      initializer "panda_core.configuration" do
        # Intentionally quiet — used as a stable anchor point
      end

      #
      # Static asset handling for:
      #   /panda-core-assets
      #
      initializer "panda_core.static_assets" do |app|
        Panda::Core::Middleware.use(
          app,
          Rack::Static,
          urls: ["/panda-core-assets"],
          root: Panda::Core::Engine.root.join("public"),
          header_rules: [
            [
              :all,
              {
                "Cache-Control" =>
                  Rails.env.development? ?
                    "no-cache, no-store, must-revalidate" :
                    "public, max-age=31536000"
              }
            ]
          ]
        )

        Panda::Core::Middleware.use(
          app,
          Panda::Core::ModuleRegistry::JavaScriptMiddleware
        )
      end
    end
  end
end

#
# Register engine with ModuleRegistry
#
Panda::Core::ModuleRegistry.register(
  gem_name: "panda-core",
  engine: "Panda::Core::Engine",
  paths: {
    builders: "app/builders/panda/core/**/*.rb",
    components: "app/components/panda/core/**/*.rb",
    helpers: "app/helpers/panda/core/**/*.rb",
    views: "app/views/panda/core/**/*.erb",
    layouts: "app/views/layouts/panda/core/**/*.erb",
    javascripts: "app/assets/javascript/panda/core/**/*.js"
  }
)
