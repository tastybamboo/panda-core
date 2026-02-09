# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Reusable dropdown menu component with a chevron trigger.
      #
      # Uses the pre-registered `dropdown` Stimulus controller from
      # tailwindcss-stimulus-components for toggle, outside-click close,
      # Escape key close, and CSS transitions.
      #
      # @example Basic dropdown
      #   <%= render Panda::Core::Admin::DropdownComponent.new do |dropdown| %>
      #     <% dropdown.with_item(label: "Edit", href: edit_path) %>
      #     <% dropdown.with_item(label: "Delete", href: delete_path, method: :delete) %>
      #   <% end %>
      #
      # @example With custom trigger content
      #   <%= render Panda::Core::Admin::DropdownComponent.new do |dropdown| %>
      #     <% dropdown.with_trigger_slot do %>
      #       <span class="text-xs text-gray-500">Last 30 days</span>
      #       <i class="fa-solid fa-chevron-down text-xs"></i>
      #     <% end %>
      #     <% dropdown.with_item(label: "Last 7 days", href: "?period=7d") %>
      #   <% end %>
      #
      class DropdownComponent < Panda::Core::Base
        renders_one :trigger_slot
        renders_many :items, "ItemComponent"

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
              class: "block w-full text-left px-4 py-2 text-xs text-gray-500 hover:bg-gray-50 hover:text-gray-700",
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

        def chevron_icon
          content_tag(:i, nil, class: "fa-solid fa-chevron-down text-xs", aria: {hidden: "true"})
        end
      end
    end
  end
end
