# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Importmap configuration
      module ImportmapConfig
        extend ActiveSupport::Concern

        included do
          # Add importmap paths from the engine
          initializer "panda_core.importmap", before: "importmap" do |app|
            if app.config.respond_to?(:importmap)
              # Create a new array if frozen
              app.config.importmap.paths = app.config.importmap.paths.dup if app.config.importmap.paths.frozen?

              # Add our paths
              app.config.importmap.paths << root.join("config/importmap.rb")

              # Handle cache sweepers similarly
              if app.config.importmap.cache_sweepers.frozen?
                app.config.importmap.cache_sweepers = app.config.importmap.cache_sweepers.dup
              end
              app.config.importmap.cache_sweepers << root.join("app/javascript")
            end
          end
        end
      end
    end
  end
end
