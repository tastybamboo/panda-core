# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module Navigation
        # A top-level navigation item
        # Can be a simple link or an expandable menu with children
        class ItemComponent < Panda::Core::Base
          BASE_CLASSES = "transition-all group flex items-center gap-x-3 px-3 " \
                         "text-sm font-medium cursor-pointer"
          SPACIOUS_PADDING = "py-2.5"
          COMPACT_PADDING = "py-1.5"
          ACTIVE_CLASSES = "bg-primary-500/20 text-white rounded-xl"
          EXPANDED_BUTTON_CLASSES = "bg-white/15 text-white rounded-t-xl"
          INACTIVE_CLASSES = "text-white/80 hover:bg-white/5 rounded-xl"

          renders_many :sub_items, SubItemComponent

          def initialize(label:, icon:, path: nil, active: false, menu_id: nil, target: nil, badge: nil, badge_color: nil, compact: false, **attrs) # rubocop:disable Metrics/ParameterLists
            @label = label
            @icon = icon
            @path = path
            @active = active
            @menu_id = menu_id
            @target = target
            @badge = badge
            @badge_color = badge_color
            @compact = compact
            super(**attrs)
          end

          attr_reader :label, :icon, :path, :active, :menu_id, :target, :badge, :badge_color

          def active?
            @active
          end

          def expandable?
            sub_items.any?
          end

          def padding_class
            @compact ? COMPACT_PADDING : SPACIOUS_PADDING
          end

          def margin_class
            @compact ? "mb-0.5" : "mb-2"
          end

          def parent_classes
            "#{BASE_CLASSES} #{padding_class} w-full #{active? ? EXPANDED_BUTTON_CLASSES : INACTIVE_CLASSES}"
          end

          def link_classes
            "#{BASE_CLASSES} #{padding_class} rounded-xl #{margin_class} #{active? ? "#{ACTIVE_CLASSES} relative" : INACTIVE_CLASSES}"
          end

          def badge_tag
            return unless badge
            helpers.content_tag(:span, badge,
              class: "ml-auto px-1.5 py-0.5 text-[10px] font-semibold rounded-full text-white",
              style: "background-color: #{badge_color || "#52B788"}")
          end
        end
      end
    end
  end
end
