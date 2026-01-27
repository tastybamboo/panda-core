# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Standardized form footer component with submit button(s) and optional secondary actions.
      #
      # @example Basic usage
      #   <%= render Panda::Core::Admin::FormFooterComponent.new(submit_text: "Save") %>
      #
      # @example With icon
      #   <%= render Panda::Core::Admin::FormFooterComponent.new(
      #     submit_text: "Create Page",
      #     icon: "fa-plus"
      #   ) %>
      #
      # @example With cancel link
      #   <%= render Panda::Core::Admin::FormFooterComponent.new(
      #     submit_text: "Update",
      #     cancel_path: admin_cms_pages_path
      #   ) %>
      #
      # @example With block for custom secondary actions
      #   <%= render Panda::Core::Admin::FormFooterComponent.new(submit_text: "Save") do %>
      #     <%= link_to "Preview", preview_path, class: "text-sm text-gray-600" %>
      #   <% end %>
      #
      class FormFooterComponent < Panda::Core::Base
        def initialize(submit_text: "Save", icon: nil, cancel_path: nil, submit_action: nil, **attrs)
          @submit_text = submit_text
          @icon = icon
          @cancel_path = cancel_path
          @submit_action = submit_action
          super(**attrs)
        end

        attr_reader :submit_text, :icon, :cancel_path, :submit_action

        def default_attrs
          {
            class: "flex justify-end gap-x-3 border-t border-gray-200 mt-6 pt-4 dark:border-white/10"
          }
        end

        def submit_button_classes
          "inline-flex items-center gap-x-1.5 justify-center rounded-md bg-mid px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-mid/80 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-mid cursor-pointer dark:shadow-none"
        end

        def cancel_link_classes
          "inline-flex items-center justify-center rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white"
        end

        def computed_icon
          return @icon if @icon

          case submit_text.to_s.downcase
          when /create|add|new/
            "fa-plus"
          when /update|save|edit/
            "fa-check"
          when /delete|remove|destroy/
            "fa-trash"
          end
        end

        def submit_data_attrs
          attrs = { disable_with: "Saving..." }
          attrs[:action] = submit_action if submit_action
          attrs
        end
      end
    end
  end
end
