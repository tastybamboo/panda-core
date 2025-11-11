# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Generator configuration
      module GeneratorConfig
        extend ActiveSupport::Concern

        included do
          config.generators do |g|
            g.test_framework :rspec
            g.fixture_replacement :factory_bot
            g.factory_bot dir: "spec/factories"
          end
        end
      end
    end
  end
end
