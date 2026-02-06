# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class AttributeDiffComponent < Panda::Core::Base
        def initialize(changes:, heading: "Attribute Changes", **attrs)
          @changes = changes
          @heading = heading
          super(**attrs)
        end

        attr_reader :changes, :heading

        def render?
          changes.any?
        end

        def display_value(value)
          if value.is_a?(FalseClass) || value.is_a?(TrueClass)
            value.to_s
          else
            value.presence || "(empty)"
          end
        end
      end
    end
  end
end
