# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # AdminController alias configuration
      module AdminControllerConfig
        extend ActiveSupport::Concern

        included do
          # Create AdminController alias after controllers are loaded
          # This allows other gems to inherit from Panda::Core::AdminController
          initializer "panda_core.admin_controller_alias", before: :eager_load! do
            # Explicitly require the base controller to ensure it's loaded
            # before any controllers try to inherit from the alias
            require_dependency "panda/core/admin/base_controller" rescue nil

            # Create the alias for convenience
            if defined?(Panda::Core::Admin::BaseController) && !Panda::Core.const_defined?(:AdminController)
              Panda::Core.const_set(:AdminController, Panda::Core::Admin::BaseController)
            end
          end
        end
      end
    end
  end
end
