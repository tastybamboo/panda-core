# frozen_string_literal: true

module Panda
  module Core
    module Engine
      module AutoloadConfig
        extend ActiveSupport::Concern

        included do
          # These must run BEFORE initialization, so this is allowed
          config.autoload_paths << root.join("app/builders")
          config.autoload_paths << root.join("app/components")
          config.autoload_paths << root.join("app/services")
          config.autoload_paths << root.join("app/models")
          config.autoload_paths << root.join("app/helpers")
          config.autoload_paths << root.join("app/constraints")

          # Mirror eager-load as needed
          config.eager_load_paths.concat(config.autoload_paths)
        end
      end
    end
  end
end
