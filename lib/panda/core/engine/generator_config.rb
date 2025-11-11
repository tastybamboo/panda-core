# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Generator configuration
      module GeneratorConfig
        extend ActiveSupport::Concern

        included do
          config.generators do |g|
            g.orm :active_record, primary_key_type: :uuid
            g.test_framework :rspec, fixture: true
            g.fixture_replacement nil
            g.view_specs false
          end
        end
      end
    end
  end
end
