# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Autoload paths configuration
      module AutoloadConfig
        extend ActiveSupport::Concern

        included do
          config.eager_load_namespaces << Panda::Core::Engine

          # Add engine's app directories to autoload paths
          # Note: Only add the root directories, not nested subdirectories
          # Zeitwerk will automatically discover nested modules from these roots
          config.autoload_paths += Dir[root.join("app", "models")]
          config.autoload_paths += Dir[root.join("app", "controllers")]
          config.autoload_paths += Dir[root.join("app", "builders")]
          config.autoload_paths += Dir[root.join("app", "components")]
          config.autoload_paths += Dir[root.join("app", "services")]
        end
      end
    end
  end
end
