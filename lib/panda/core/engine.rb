require "rubygems"
require "stringio"
require "rails/engine"
require "omniauth"

# Load shared configuration modules
require_relative "shared/inflections_config"
require_relative "shared/generator_config"

# Load engine configuration modules
require_relative "engine/autoload_config"
require_relative "engine/middleware_config"
require_relative "engine/importmap_config"
require_relative "engine/omniauth_config"
require_relative "engine/phlex_config"
require_relative "engine/admin_controller_config"

# Load module registry
require_relative "module_registry"

module Panda
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Core

      # Include shared configuration modules
      include Shared::InflectionsConfig
      include Shared::GeneratorConfig

      # Include engine-specific configuration modules
      include AutoloadConfig
      include MiddlewareConfig
      include ImportmapConfig
      include OmniauthConfig
      include PhlexConfig
      include AdminControllerConfig

      initializer "panda_core.config" do |app|
        # Configuration is already initialized with defaults in Configuration class
      end

      # Static asset middleware for serving public files and JavaScript modules
      # Must run before Propshaft to intercept /panda/* requests, but we can't
      # guarantee Propshaft is in the host application, so just insert it
      # high up in the middleware stack
      initializer "panda.core.static_assets" do |app|
        # Serve public assets (CSS, images, etc.)
        app.config.middleware.insert_before ActionDispatch::Static, Rack::Static,
          urls: ["/panda-core-assets"],
          root: Panda::Core::Engine.root.join("public"),
          header_rules: [
            # Disable caching in development for instant CSS updates
            [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000"}]
          ]

        # Use ModuleRegistry's custom middleware to serve JavaScript from all registered modules
        # This middleware checks all modules and serves from the first matching location
        app.config.middleware.insert_before ActionDispatch::Static, Panda::Core::ModuleRegistry::JavaScriptMiddleware
      end
    end
  end
end

# Register Core module with ModuleRegistry for JavaScript serving
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
