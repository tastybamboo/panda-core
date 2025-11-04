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
        prop :items, Array, default: -> { [] }
        prop :show_back, _Boolean, default: true

        def view_template
          div do
            # Mobile back link
            if @show_back && @items.any?
              nav(
                aria: {label: "Back"},
                class: "sm:hidden"
              ) do
                a(
                  href: back_link_href,
                  class: "flex items-center text-sm font-medium text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                ) do
                  render_chevron_left_icon
                  plain "Back"
                end
              end
            end

            # Desktop breadcrumb trail
            nav(
              aria: {label: "Breadcrumb"},
              class: "hidden sm:flex"
            ) do
              ol(
                role: "list",
                class: "flex items-center space-x-4"
              ) do
                @items.each_with_index do |item, index|
                  li do
                    if index.zero?
                      # First item (no separator)
                      div(class: "flex") do
                        a(
                          href: item[:href],
                          class: breadcrumb_link_classes(index)
                        ) { item[:text] }
                      end
                    else
                      # Subsequent items (with separator)
                      div(class: "flex items-center") do
                        render_chevron_right_icon
                        a(
                          href: item[:href],
                          aria: ((index == @items.length - 1) ? {current: "page"} : nil),
                          class: breadcrumb_link_classes(index)
                        ) { item[:text] }
                      end
                    end
                  end
                end
              end
            end
          end
        end

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
          svg(
            viewBox: "0 0 20 20",
            fill: "currentColor",
            data: {slot: "icon"},
            aria: {hidden: "true"},
            class: "mr-1 -ml-1 size-5 shrink-0 text-gray-400 dark:text-gray-500"
          ) do |s|
            s.path(
              d: "M11.78 5.22a.75.75 0 0 1 0 1.06L8.06 10l3.72 3.72a.75.75 0 1 1-1.06 1.06l-4.25-4.25a.75.75 0 0 1 0-1.06l4.25-4.25a.75.75 0 0 1 1.06 0Z",
              clip_rule: "evenodd",
              fill_rule: "evenodd"
            )
          end
        end

        def render_chevron_right_icon
          svg(
            viewBox: "0 0 20 20",
            fill: "currentColor",
            data: {slot: "icon"},
            aria: {hidden: "true"},
            class: "size-5 shrink-0 text-gray-400 dark:text-gray-500"
          ) do |s|
            s.path(
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
