# frozen_string_literal: true

module Panda
  module Core
    module Shared
      # Shared generator configuration for all panda gems
      # This ensures consistent generator behavior across the ecosystem
      module GeneratorConfig
        extend ActiveSupport::Concern

        included do
          # `config.generators` is deep-copied per engine by
          # Rails::Engine::Configuration, so this governs generators run inside the
          # engine and nothing else. Deliberately NOT `config.app_generators`, which
          # is shared with the host application: Rails' own Active Storage and
          # Action Text migrations read Rails.configuration.generators at migration
          # time to pick their primary and foreign key types, so setting it there
          # would silently retype the host app's active_storage_blobs. What Active
          # Storage uses is the host's decision — see docs/migration-paths.md.
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
