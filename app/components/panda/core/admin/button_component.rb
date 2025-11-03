# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ButtonComponent < Panda::Core::Base
        prop :text, String, default: "Button"
        prop :action, _Nilable(Symbol), default: -> {}
        prop :href, String, default: "#"
        prop :icon, _Nilable(String), default: -> {}
        prop :size, Symbol, default: :regular
        prop :id, _Nilable(String), default: -> {}

        def view_template
          a(**@attrs) do
            if computed_icon
              i(class: "mr-2 fa-solid fa-#{computed_icon}")
              plain " "
            end
            plain @text.titleize
          end
        end

        def default_attrs
          {
            href: @href,
            class: button_classes,
            id: @id
          }
        end

        private

        def computed_icon
          @computed_icon ||= @icon || icon_from_action(@action)
        end

        def button_classes
          base = "inline-flex items-center rounded-md font-medium shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 "
          base + size_classes + action_classes
        end

        def size_classes
          case @size
          when :small, :sm
            "gap-x-1.5 px-2.5 py-1.5 text-sm "
          when :medium, :regular, :md
            "gap-x-1.5 px-3 py-2 text-base "
          when :large, :lg
            "gap-x-2 px-3.5 py-2.5 text-lg "
          else
            "gap-x-1.5 px-3 py-2 text-base "
          end
        end

        def action_classes
          case @action
          when :save, :create
            "text-white bg-green-600 hover:bg-green-700"
          when :save_inactive
            "text-white bg-gray-400"
          when :secondary
            "text-gray-700 border-2 border-gray-700 bg-transparent hover:bg-gray-100 transition-all"
          when :delete, :destroy, :danger
            "text-red-600 border border-red-600 bg-red-100 hover:bg-red-200 hover:text-red-700 focus-visible:outline-red-300"
          else
            "text-gray-700 border-2 border-gray-700 bg-transparent hover:bg-gray-100 transition-all"
          end
        end

        def icon_from_action(action)
          return nil unless action

          case action
          when :add, :new, :create
            "plus"
          when :save
            "check"
          when :edit, :update
            "pencil"
          when :delete, :destroy
            "trash"
          end
        end
      end
    end
  end
end
