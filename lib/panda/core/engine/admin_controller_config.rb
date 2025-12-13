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
          initializer "panda_core.admin_controller_alias", after: :load_config_initializers do
            ActiveSupport.on_load(:action_controller_base) do
              # Eager load the BaseController to avoid autoload issues in production
              require_dependency "panda/core/admin/base_controller" if defined?(Rails) && Rails.env.production?
              Panda::Core.const_set(:AdminController, Panda::Core::Admin::BaseController) unless Panda::Core.const_defined?(:AdminController)
            end
          end
        end
      end
    end
  end
end
