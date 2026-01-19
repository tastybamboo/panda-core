# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Breadcrumb navigation component with responsive behavior.
      #
      # Shows a "Back" link on mobile and full breadcrumb trail on larger screens.
      # Follows Tailwind UI Plus pattern for breadcrumb navigation.
      #
      # @example Basic breadcrumbs
      #   render Panda::Core::Admin::BreadcrumbComponent.new(
      #     items: [
      #       { text: "Pages", href: "/admin/pages" },
      #       { text: "Blog Posts", href: "/admin/pages/blog" },
      #       { text: "Edit Post", href: "/admin/pages/blog/1/edit" }
      #     ]
      #   )
      #
      # @example Without back link (first page in section)
      #   render Panda::Core::Admin::BreadcrumbComponent.new(
      #     items: [
      #       { text: "Dashboard", href: "/admin" }
      #     ],
      #     show_back: false
      #   )
      #
      class BreadcrumbComponent < Panda::Core::Base
        def initialize(items: [], show_back: true, **attrs)
          @items = items
          @show_back = show_back
          super(**attrs)
        end

        attr_reader :items, :show_back

        private

        def back_link_href
          (@items.length > 1) ? @items[-2][:href] : @items.first[:href]
        end

        def breadcrumb_link_classes(index)
          base = "text-sm font-medium text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
          base += " ml-4" unless index.zero?
          base
        end

        def render_chevron_left_icon
          content_tag(:svg,
            viewBox: "0 0 20 20",
            fill: "currentColor",
            data: {slot: "icon"},
            aria: {hidden: "true"},
            class: "mr-1 -ml-1 size-5 shrink-0 text-gray-400 dark:text-gray-500") do
            tag.path(
              d: "M11.78 5.22a.75.75 0 0 1 0 1.06L8.06 10l3.72 3.72a.75.75 0 1 1-1.06 1.06l-4.25-4.25a.75.75 0 0 1 0-1.06l4.25-4.25a.75.75 0 0 1 1.06 0Z",
              clip_rule: "evenodd",
              fill_rule: "evenodd"
            )
          end
        end

        def render_chevron_right_icon
          content_tag(:svg,
            viewBox: "0 0 20 20",
            fill: "currentColor",
            data: {slot: "icon"},
            aria: {hidden: "true"},
            class: "size-5 shrink-0 text-gray-400 dark:text-gray-500") do
            tag.path(
              d: "M8.22 5.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L11.94 10 8.22 6.28a.75.75 0 0 1 0-1.06Z",
              clip_rule: "evenodd",
              fill_rule: "evenodd"
            )
          end
        end
      end
    end
  end
end
