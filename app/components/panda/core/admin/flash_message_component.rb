# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FlashMessageComponent < Panda::Core::Base
    def initialize(message: "", kind: :default, temporary: true, subtitle: nil, **attrs)
    @message = message
    @kind = kind
    @temporary = temporary
    @subtitle = subtitle
      super(**attrs)
    end

    attr_reader :message, :kind, :temporary, :subtitle


        def notification_attrs
          {
            class: "pointer-events-auto w-full max-w-sm translate-y-0 transform rounded-lg bg-white opacity-100 shadow-lg transition duration-300 ease-out sm:translate-x-0 dark:bg-gray-800 starting:translate-y-2 starting:opacity-0 starting:sm:translate-x-2 starting:sm:translate-y-0 #{border_color_css}",
            data: {
              controller: "alert",
              alert_dismiss_after_value: (@temporary ? "5000" : nil)
            }.compact
          }
        end

        def render_icon
          content_tag(:div, class: "shrink-0") do
            content_tag(:i, "", class: "fa-solid size-6 #{icon_css} #{icon_colour_css}")
          end
        end

        def render_content
          content_tag(:div, class: "ml-3 w-0 flex-1 pt-0.5") do
            message_html = content_tag(:p, @message, class: "text-sm font-medium text-gray-900 dark:text-white flash-message-title")
            subtitle_html = if @subtitle
              content_tag(:p, @subtitle, class: "mt-1 text-sm text-gray-500 dark:text-gray-400 flash-message-subtitle")
            else
              "".html_safe
            end
            (message_html + subtitle_html).html_safe
          end
        end

        def render_close_button
          content_tag(:div, class: "ml-4 flex shrink-0") do
            content_tag(:button,
              type: "button",
              class: "inline-flex rounded-md text-gray-400 hover:text-gray-500 focus:outline-2 focus:outline-offset-2 focus:outline-blue-600 dark:hover:text-white dark:focus:outline-blue-500",
              data: {action: "alert#close"}
            ) do
              sr_only = content_tag(:span, "Close", class: "sr-only")
              icon_svg = content_tag(:svg,
                viewBox: "0 0 20 20",
                fill: "currentColor",
                data: {slot: "icon"},
                aria: {hidden: "true"},
                class: "size-5"
              ) do
                tag.path(
                  d: "M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z"
                )
              end
              (sr_only + icon_svg).html_safe
            end
          end
        end

        def icon_colour_css
          case @kind
          when :success
            "text-green-400 dark:text-green-500"
          when :alert, :error
            "text-red-400 dark:text-red-500"
          when :warning
            "text-yellow-400 dark:text-yellow-500"
          when :info, :notice
            "text-blue-400 dark:text-blue-500"
          else
            "text-gray-400 dark:text-gray-500"
          end
        end

        def border_color_css
          case @kind
          when :success
            "ring-2 ring-green-400/20 dark:ring-green-500/30"
          when :alert, :error
            "ring-2 ring-red-400/20 dark:ring-red-500/30"
          when :warning
            "ring-2 ring-yellow-400/20 dark:ring-yellow-500/30"
          when :info, :notice
            "ring-2 ring-blue-400/20 dark:ring-blue-500/30"
          else
            "ring-1 ring-gray-400/10 dark:ring-gray-500/20"
          end
        end

        def icon_css
          case @kind
          when :success
            "fa-circle-check"
          when :alert, :error
            "fa-circle-xmark"
          when :warning
            "fa-triangle-exclamation"
          when :info, :notice
            "fa-circle-info"
          else
            "fa-circle-info"
          end
        end
      end
    end
  end
end
