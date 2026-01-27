# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Standardized form section component for grouping related form fields.
      # Provides a consistent heading style for form sections without the heavy
      # visual weight of PanelComponent.
      #
      # @example Basic usage
      #   <%= render Panda::Core::Admin::FormSectionComponent.new(title: "SEO Settings") do %>
      #     <%= f.text_field :seo_title %>
      #     <%= f.text_area :seo_description %>
      #   <% end %>
      #
      # @example With description
      #   <%= render Panda::Core::Admin::FormSectionComponent.new(
      #     title: "Notification Settings",
      #     description: "Configure how you receive notifications"
      #   ) do %>
      #     ...
      #   <% end %>
      #
      # @example With icon
      #   <%= render Panda::Core::Admin::FormSectionComponent.new(
      #     title: "Menu Items",
      #     icon: "fa-bars"
      #   ) do %>
      #     ...
      #   <% end %>
      #
      class FormSectionComponent < Panda::Core::Base
        def initialize(title:, description: nil, icon: nil, border_top: true, **attrs)
          @title = title
          @description = description
          @icon = icon
          @border_top = border_top
          super(**attrs)
        end

        attr_reader :title, :description, :icon, :border_top

        def default_attrs
          base_classes = "mt-6 pt-4"
          base_classes += " border-t border-gray-200 dark:border-white/10" if border_top

          { class: base_classes }
        end

        def heading_classes
          "text-base font-semibold text-gray-900 dark:text-white flex items-center gap-2"
        end

        def description_classes
          "mt-1 text-sm text-gray-500 dark:text-gray-400"
        end

        def content_classes
          "mt-4 space-y-4"
        end
      end
    end
  end
end
