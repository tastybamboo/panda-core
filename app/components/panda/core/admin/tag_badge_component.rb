# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TagBadgeComponent < Panda::Core::Base
        attr_reader :tag, :removable

        def initialize(tag:, removable: false, **attrs)
          @tag = tag
          @removable = removable
          super(**attrs)
        end

        def colour
          tag.display_colour
        end
      end
    end
  end
end
