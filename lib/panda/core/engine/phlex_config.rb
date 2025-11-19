# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Phlex configuration
      module PhlexConfig
        extend ActiveSupport::Concern

        included do
          # Exclude preview paths from production eager loading
          # Preview classes should only be loaded in development/test environments
          initializer "panda_core.exclude_previews_from_production", before: :set_autoload_paths do |app|
            if Rails.env.production?
              # Prevent eager loading of preview files in production
              preview_paths = [
                root.join("spec/components/previews").to_s
              ]

              preview_paths.each do |preview_path|
                if Dir.exist?(preview_path)
                  app.config.eager_load_paths.delete(preview_path)
                  ActiveSupport::Dependencies.autoload_paths.delete(preview_path)
                end
              end
            end
          end

          # Load Phlex base component after Rails application is initialized
          # This ensures Rails.application.routes is available
          initializer "panda_core.phlex_base", after: :load_config_initializers do
            require "phlex"
            require "phlex-rails"
            require "literal"
            require "tailwind_merge"

            # Load the base component
            require root.join("app/components/panda/core/base")
          end
        end
      end
    end
  end
end
