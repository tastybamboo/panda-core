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
            class: "pointer-events-auto w-full max-w-sm translate-y-0 transform rounded-2xl border px-4 py-3 shadow-lg transition duration-300 ease-out sm:translate-x-0 starting:translate-y-2 starting:opacity-0 starting:sm:translate-x-2 starting:sm:translate-y-0 #{tone_classes}",
            data: {
              controller: "alert",
              alert_dismiss_after_value: (@temporary ? "5000" : nil)
            }.compact
          }
        end

        def render_icon
          content_tag(:div, class: "shrink-0") do
            content_tag(:i, "", class: "fa-solid size-5 #{icon_css} #{icon_colour_css}")
          end
        end

        def render_content
          content_tag(:div, class: "ml-3 w-0 flex-1") do
            message_html = content_tag(:p, @message, class: "text-sm font-medium flash-message-title")
            subtitle_html = if @subtitle
              content_tag(:p, @subtitle, class: "mt-1 text-xs opacity-80 flash-message-subtitle")
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
              class: "inline-flex items-center gap-1 text-xs font-medium opacity-80 hover:opacity-100",
              data: {action: "alert#close"}) do
              close_text = content_tag(:span, "Close")
              icon = content_tag(:i, "", class: "fa-solid fa-xmark")
              (close_text + icon).html_safe
            end
          end
        end

        def icon_colour_css
          case @kind
          when :success
            "text-emerald-600"
          when :alert, :error
            "text-rose-600"
          when :warning
            "text-amber-600"
          when :info, :notice
            "text-sky-600"
          else
            "text-slate-500"
          end
        end

        def tone_classes
          case @kind
          when :success
            "bg-emerald-50 text-emerald-700 border-emerald-200"
          when :alert, :error
            "bg-rose-50 text-rose-700 border-rose-200"
          when :warning
            "bg-amber-50 text-amber-700 border-amber-200"
          when :info, :notice
            "bg-sky-50 text-sky-700 border-sky-200"
          else
            "bg-white text-slate-700 border-slate-200"
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
