# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module Navigation
        # User profile menu component for the sidebar footer
        # Displays user avatar/name with expandable menu for profile, security, and logout
        class UserMenuComponent < Panda::Core::Base
          BASE_CLASSES = 'transition-colors group flex items-center w-full gap-x-3 px-3 py-2.5 ' \
                         'rounded-xl text-sm font-medium'
          ACTIVE_CLASSES = 'bg-primary-500/20 text-white ring-1 ring-primary-400/30'
          INACTIVE_CLASSES = 'text-white/80 hover:bg-white/5'

          renders_many :sub_items, SubItemComponent

          def initialize(user:, active: false, **attrs)
            @user = user
            @active = active
            super(**attrs)
          end

          attr_reader :user

          def active?
            @active
          end

          def button_classes
            "#{BASE_CLASSES} #{active? ? ACTIVE_CLASSES : INACTIVE_CLASSES}"
          end
        end
      end
    end
  end
end
