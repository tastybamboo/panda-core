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
          config.to_prepare do
            # Use on_load to ensure ActionController is available
            ActiveSupport.on_load(:action_controller_base) do
              # Create the alias if it doesn't exist
              unless Panda::Core.const_defined?(:AdminController)
                Panda::Core.const_set(:AdminController, Panda::Core::Admin::BaseController)
              end
            end
          end
        end
      end
    end
  end
end
