# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      module AutoloadConfig
        extend ActiveSupport::Concern

        # Custom autoload paths for panda-core
        # Note: Must be Strings (not Pathnames) for Rails 8.1.2+ compatibility
        AUTOLOAD_DIRECTORIES = %w[
          app/builders
          app/components
          app/services
          app/models
          app/helpers
          app/constraints
        ].freeze

        included do
          # Use initializer with before: to ensure paths are added before
          # Rails freezes the autoload_paths array in Rails 8.1.2+
          initializer "panda_core.set_autoload_paths", before: :set_autoload_paths do |app|
            AUTOLOAD_DIRECTORIES.each do |dir|
              path = root.join(dir).to_s
              next unless File.directory?(path)

              app.config.autoload_paths << path unless app.config.autoload_paths.include?(path)
              app.config.eager_load_paths << path unless app.config.eager_load_paths.include?(path)
            end
          end
        end
      end
    end
  end
end
