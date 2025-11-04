# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SlideoverComponent < Panda::Core::Base
        prop :title, String, default: "Settings"
        prop :open, _Nilable(_Boolean), default: -> { false }

        def view_template(&block)
          # Capture block content
          if block_given?
            if defined?(view_context) && view_context
              @content_html = view_context.capture(&block)
            else
              @content_block = block
            end
          end

          div(
            **default_attrs,
            data: {
              toggle_target: "toggleable",
              transition_enter: "transform transition ease-in-out duration-500",
              transition_enter_from: "translate-x-full",
              transition_enter_to: "translate-x-0",
              transition_leave: "transform transition ease-in-out duration-500",
              transition_leave_from: "translate-x-0",
              transition_leave_to: "translate-x-full"
            }
          ) do
            # Header with title and close button
            div(class: "py-3 px-4 mb-4 bg-black") do
              div(class: "flex justify-between items-center") do
                h2(class: "text-base font-semibold leading-6 text-white", id: "slideover-title") do
                  i(class: "mr-2 fa-light fa-gear")
                  plain " #{@title}"
                end
                button(
                  type: "button",
                  data: {action: "click->toggle#toggle touch->toggle#toggle"},
                  class: "text-white hover:text-gray-300 transition"
                ) do
                  i(class: "font-bold fa-regular fa-xmark right")
                end
              end
            end

            # Content area
            div(class: "overflow-y-auto px-4 pb-6 space-y-6") do
              if @content_html
                raw(@content_html)
              elsif @content_block
                instance_eval(&@content_block)
              end
            end
          end
        end

        private

        def default_attrs
          {
            id: "slideover",
            class: slideover_classes
          }
        end

        def slideover_classes
          base = "flex absolute right-0 flex-col h-full bg-white divide-y divide-gray-200 shadow-xl basis-3/12 z-50"
          visibility = @open ? "" : "hidden"
          [base, visibility].compact.join(" ")
        end
      end
    end
  end
end
