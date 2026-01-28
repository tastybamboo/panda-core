# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module Navigation
        # A child item within an expandable navigation menu
        # Can render as a link or a button (for logout, etc.)
        class SubItemComponent < Panda::Core::Base
          BASE_CLASSES = 'group flex items-center w-full py-2 pr-2 pl-6 rounded-md ' \
                         'text-sm font-normal transition-all'
          ACTIVE_CLASSES = 'bg-primary-500 text-white shadow-sm'
          INACTIVE_CLASSES = 'text-white hover:bg-primary-500/40'

          # rubocop:disable Metrics/ParameterLists
          def initialize(label:, path: nil, active: false, method: nil, button_options: {}, **attrs)
            @label = label
            @path = path
            @active = active
            @method = method
            @button_options = button_options
            super(**attrs)
          end
          # rubocop:enable Metrics/ParameterLists

          attr_reader :label, :path, :active, :method, :button_options

          def active?
            @active
          end

          def button?
            method.present?
          end

          def item_classes
            "#{BASE_CLASSES} #{active? ? ACTIVE_CLASSES : INACTIVE_CLASSES}"
          end
        end
      end
    end
  end
end
