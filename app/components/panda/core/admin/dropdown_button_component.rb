# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # A button-styled dropdown menu. Combines ButtonComponent styling with
      # DropdownComponent behaviour (Stimulus `dropdown` controller).
      #
      # @example In a heading slot
      #   heading.with_dropdown_button(text: "View Board") do |db|
      #     db.with_item(label: "Fundraising", href: "/boards/1")
      #     db.with_item(label: "Events",      href: "/boards/2")
      #   end
      #
      class DropdownButtonComponent < Panda::Core::Base
        renders_many :items, "ItemComponent"

        def initialize(text: "Options", action: :secondary, icon: nil, size: :regular, **attrs)
          @text = text
          @action = action
          @icon = icon
          @size = size
          super(**attrs)
          yield self if block_given?
        end

        attr_reader :text, :action, :icon, :size

        class ItemComponent < Panda::Core::Base
          def initialize(label:, href: "#", method: nil, **attrs)
            @label = label
            @href = href
            @method = method
            super(**attrs)
          end

          attr_reader :label, :href, :method

          def call
            options = {
              class: "block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 hover:text-gray-900",
              role: "menuitem",
              data: {dropdown_target: "menuItem"}
            }
            options[:data][:turbo_method] = method if method

            content_tag(:a, label, **options.merge(href: href))
          end
        end

        private

        def default_attrs
          {class: "relative inline-block text-left"}
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
          when :save, :create, :add, :new
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

        def render_text
          parts = []
          parts << content_tag(:i, "", class: "fa-solid fa-#{@icon}") if @icon
          parts << @text.titleize
          parts << content_tag(:i, "", class: "fa-solid fa-chevron-down text-xs", aria: {hidden: "true"})
          safe_join(parts)
        end
      end
    end
  end
end
