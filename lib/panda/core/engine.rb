# frozen_string_literal: true

require "rails"
require "omniauth"

require "panda/core/middleware"
require "panda/core/module_registry"
require "panda/core/search_registry"

# Shared engine mixins
require_relative "shared/inflections_config"
require_relative "shared/generator_config"

# Engine mixins
require_relative "engine/autoload_config"
require_relative "engine/importmap_config"
require_relative "engine/omniauth_config"
require_relative "engine/view_component_config"
require_relative "engine/admin_controller_config"
require_relative "engine/route_config"

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
      include ViewComponentConfig
      include AdminControllerConfig
      include RouteConfig

      #
      # Misc configuration point
      #
      initializer "panda_core.configuration" do
        # Intentionally quiet — used as a stable anchor point
      end

      #
      # Auto-categorize files when ActiveStorage attachments are created.
      # Maps known attachment types (user avatars, page images, etc.) to
      # their corresponding file categories via FileCategorizer.
      #
      initializer "panda_core.active_storage_categorization" do
        ActiveSupport.on_load(:active_storage_attachment) do
          after_create_commit :auto_categorize_blob

          private

          def auto_categorize_blob
            Panda::Core::FileCategorizer.new.categorize_attachment(self)
          rescue => e
            Rails.logger.warn("[Panda::Core] Auto-categorization failed for blob #{blob_id}: #{e.message}")
          end
        end
      end

      #
      # Static asset handling for:
      #   /panda-core-assets
      #
      # Configured during engine load phase to avoid Rails 8.1.2+ frozen middleware stack
      # Use no-cache in development for easier debugging, long cache in production
      config.app_middleware.use(
        Rack::Static,
        urls: ["/panda-core-assets"],
        root: Panda::Core::Engine.root.join("public"),
        header_rules: [
          [
            :all,
            {
              "Cache-Control" => if defined?(::Rails) && ::Rails.env.development?
                                   "no-cache, no-store, must-revalidate"
                                 else
                                   "public, max-age=31536000"
                                 end
            }
          ]
        ]
      )

      config.app_middleware.use(Panda::Core::ModuleRegistry::JavaScriptMiddleware)

      #
      # Serve Chartkick vendor assets when the chartkick gem is available
      # Must be inserted BEFORE Rack::Static so it handles chartkick requests
      # before Rack::Static catches all /panda-core-assets/* paths and returns 404
      #
      if Gem.loaded_specs["chartkick"]
        config.app_middleware.insert_before(Rack::Static, Panda::Core::ChartkickAssetMiddleware)
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
    components: "app/components/panda/core/**/*.{rb,erb,js}",
    helpers: "app/helpers/panda/core/**/*.rb",
    views: "app/views/panda/core/**/*.erb",
    layouts: "app/views/layouts/panda/core/**/*.erb",
    javascripts: "app/assets/javascript/panda/core/**/*.js"
  }
)
