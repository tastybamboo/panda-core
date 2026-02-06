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
      end
    end
  end
end
