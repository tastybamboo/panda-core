# frozen_string_literal: true

module Panda
  module Core
    module Shared
      # Shared inflections configuration for all panda gems
      # Ensures consistent constant naming across the ecosystem
      module InflectionsConfig
        extend ActiveSupport::Concern

        included do
          # Load inflections early to ensure proper constant resolution
          initializer "panda.inflections", before: :load_config_initializers do
            ActiveSupport::Inflector.inflections(:en) do |inflect|
              inflect.acronym "CMS"
              inflect.acronym "SEO"
              inflect.acronym "AI"
              inflect.acronym "UUID"
            end
          end
        end
      end
    end
  end
end
