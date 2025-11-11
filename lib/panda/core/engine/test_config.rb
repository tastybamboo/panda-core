# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Test environment configuration
      module TestConfig
        extend ActiveSupport::Concern

        included do
          # For testing: Don't expose engine migrations since we use "copy to host app" strategy
          # In test environment, migrations should be copied to the host app
          if Rails.env.test?
            config.paths["db/migrate"] = []
          end
        end
      end
    end
  end
end
