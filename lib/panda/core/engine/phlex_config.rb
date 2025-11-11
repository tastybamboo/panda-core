# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Phlex configuration
      module PhlexConfig
        extend ActiveSupport::Concern

        included do
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
