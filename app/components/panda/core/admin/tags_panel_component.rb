# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Renders a PanelComponent containing TagBadgeComponents for a collection of tags.
      # Self-hides via `render?` when the tags collection is empty.
      #
      # Lives in panda-core because tags are a core Panda concept (Panda::Core::Tag)
      # and this component composes two existing panda-core components (PanelComponent
      # and TagBadgeComponent) into a pattern used on most admin show pages.
      #
      # @example Basic usage
      #   render Panda::Core::Admin::TagsPanelComponent.new(tags: @person.tags)
      #
      # @example Custom heading
      #   render Panda::Core::Admin::TagsPanelComponent.new(tags: @item.tags, heading: "Categories")
      class TagsPanelComponent < Panda::Core::Base
        attr_reader :tags, :heading

        def initialize(tags:, heading: "Tags", **attrs)
          @tags = tags
          @heading = heading
          super(**attrs)
        end

        def render?
          tags.present? && tags.any?
        end
      end
    end
  end
end
