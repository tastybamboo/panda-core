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

      include Shared::InflectionsConfig
      include Shared::GeneratorConfig

      include AutoloadConfig
      include MiddlewareConfig
      include ImportmapConfig
      include OmniauthConfig
      include PhlexConfig
      include AdminControllerConfig

      app.config.middleware.insert_before Rack::Sendfile, Rack::Static,
        urls: ["/panda-core-assets"],
        root: Panda::Core::Engine.root.join("public"),
        header_rules: [
          [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000"}]
        ]

      config.middleware.insert_before Rack::Sendfile,
        Panda::Core::ModuleRegistry::JavaScriptMiddleware
    end
  end
end

# Register for JS module serving
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
