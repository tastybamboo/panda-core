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
              # Safely create the alias, handling cases where BaseController isn't loaded yet
              begin
                base_controller = "Panda::Core::Admin::BaseController".constantize
                Panda::Core.const_set(:AdminController, base_controller) unless Panda::Core.const_defined?(:AdminController)
              rescue NameError => e
                # BaseController not loaded yet - this is fine during asset precompilation
                Rails.logger.debug("Skipping AdminController alias setup: #{e.message}") if Rails.logger
              end
            end
          end
        end
      end
    end
  end
end
