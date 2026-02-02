# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module Navigation
        # A top-level navigation item
        # Can be a simple link or an expandable menu with children
        class ItemComponent < Panda::Core::Base
          BASE_CLASSES = 'transition-colors group flex items-center gap-x-3 px-3 py-2.5 ' \
                         'rounded-xl text-sm font-medium'
          ACTIVE_CLASSES = 'bg-primary-500/20 text-white'
          EXPANDED_CLASSES = 'text-white'
          INACTIVE_CLASSES = 'text-white/80 hover:bg-white/5'

          renders_many :sub_items, SubItemComponent

          def initialize(label:, icon:, path: nil, active: false, menu_id: nil, **attrs) # rubocop:disable Metrics/ParameterLists
            @label = label
            @icon = icon
            @path = path
            @active = active
            @menu_id = menu_id
            super(**attrs)
          end

          attr_reader :label, :icon, :path, :active, :menu_id

          def active?
            @active
          end

          def expandable?
            sub_items.any?
          end

          def parent_classes
            "#{BASE_CLASSES} w-full #{active? ? EXPANDED_CLASSES : INACTIVE_CLASSES}"
          end

          def link_classes
            base = "#{BASE_CLASSES} mb-2"
            "#{base} #{active? ? "#{ACTIVE_CLASSES} relative" : INACTIVE_CLASSES}"
          end
        end
      end
    end
  end
end
