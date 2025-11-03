# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FlashMessageComponent < Panda::Core::Base
        prop :message, String
        prop :kind, Symbol
        prop :temporary, _Boolean, default: true

        def view_template
          div(**container_attrs) do
            div(class: "overflow-hidden w-full max-w-sm bg-white rounded-lg ring-1 ring-black ring-opacity-5 shadow-lg") do
              div(class: "p-4") do
                div(class: "flex items-start") do
                  render_icon
                  render_content
                  render_close_button
                end
              end
            end
          end
        end

        private

        def container_attrs
          attrs = {
            class: "fixed top-2 right-2 z-[9999] p-2 space-y-4 w-full max-w-sm sm:items-end",
            data: {
              controller: "alert",
              alert_dismiss_after_value: (@temporary ? "5000" : nil),
              transition_enter: "ease-in-out duration-500",
              transition_enter_from: "translate-x-full opacity-0",
              transition_enter_to: "translate-x-0 opacity-100",
              transition_leave: "ease-in-out duration-500",
              transition_leave_from: "translate-x-0 opacity-100",
              transition_leave_to: "translate-x-full opacity-0"
            }.compact
          }

          attrs
        end

        def render_icon
          div(class: "flex-shrink-0") do
            i(class: "fa-solid text-xl #{icon_css} #{text_colour_css}")
          end
        end

        def render_content
          div(class: "flex-1 pt-0.5 ml-3 w-0") do
            p(class: "mb-1 text-sm font-medium flash-message-title #{text_colour_css}") { @kind.to_s.titleize }
            p(class: "mt-1 mb-0 text-sm text-gray-500 flash-message-text") { @message }
          end
        end

        def render_close_button
          div(class: "flex flex-shrink-0 ml-4") do
            button(
              type: "button",
              class: "inline-flex text-gray-400 bg-white rounded-md transition duration-150 ease-in-out hover:text-gray-500 focus:ring-2 focus:ring-offset-2 focus:outline-none focus:ring-sky-500",
              data: {action: "alert#close"}
            ) do
              span(class: "sr-only") { "Close" }
              svg(
                class: "w-5 h-5",
                viewBox: "0 0 20 20",
                fill: "currentColor",
                aria: {hidden: "true"}
              ) do |s|
                s.path(
                  d: "M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
                )
              end
            end
          end
        end

        def text_colour_css
          case @kind
          when :success
            "text-green-600"
          when :alert, :error
            "text-red-600"
          when :warning
            "text-yellow-600"
          when :info, :notice
            "text-blue-600"
          else
            "text-gray-600"
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
