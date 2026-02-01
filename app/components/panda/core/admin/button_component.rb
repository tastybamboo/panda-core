# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ButtonComponent < Panda::Core::Base
        def initialize(text: "Button", action: nil, href: "#", icon: nil, size: :regular, id: nil, as_button: false, **attrs)
          @text = text
          @action = action
          @href = href
          @icon = icon
          @size = size
          @id = id
          @as_button = as_button
          super(**attrs)
        end

        attr_reader :text, :action, :href, :icon, :size, :id, :as_button

        def default_attrs
          base = {
            class: button_classes,
            id: @id
          }

          if @as_button
            base.merge(type: "button")
          else
            base.merge(href: @href)
          end
        end

        private

        def render_content
          icon_html = if computed_icon
            content_tag(:i, "", class: "fa-solid fa-#{computed_icon}")
          else
            "".html_safe
          end
          text_html = @text.titleize
          (icon_html + text_html).html_safe
        end

        def computed_icon
          @computed_icon ||= @icon || icon_from_action(@action)
        end

        def button_classes
          base = "inline-flex items-center rounded-xl font-medium shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 cursor-pointer transition-colors "
          base + size_classes + action_classes
        end

        def size_classes
          case @size
          when :small, :sm
            "gap-x-1.5 px-3 py-1.5 text-xs "
          when :medium, :regular, :md
            "gap-x-2 px-4 py-2 text-sm "
          when :large, :lg
            "gap-x-2 px-5 py-2.5 text-base "
          else
            "gap-x-2 px-4 py-2 text-sm "
          end
        end

        def action_classes
          case @action
          when :save, :create
            "text-white bg-primary-500 hover:bg-primary-600 focus-visible:outline-primary-600"
          when :save_inactive
            "text-white bg-gray-300 cursor-not-allowed"
          when :secondary
            "text-gray-700 border border-gray-200 bg-white hover:bg-gray-50"
          when :delete, :destroy, :danger
            "text-error-600 border border-error-200 bg-error-50 hover:bg-error-100 focus-visible:outline-error-300"
          else
            "text-gray-700 border border-gray-200 bg-white hover:bg-gray-50"
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
