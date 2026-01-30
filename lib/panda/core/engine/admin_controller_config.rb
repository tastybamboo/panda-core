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
            unless Panda::Core.const_defined?(:AdminController)
              admin_base = "Panda::Core::Admin::BaseController".safe_constantize
              Panda::Core.const_set(:AdminController, admin_base) if admin_base
            end
          end
        end
      end
    end
  end
end
