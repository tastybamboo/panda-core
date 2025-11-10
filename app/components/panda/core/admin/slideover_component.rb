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
              transition_enter: "transform transition ease-in-out duration-500 sm:duration-700",
              transition_enter_from: "translate-x-full",
              transition_enter_to: "translate-x-0",
              transition_leave: "transform transition ease-in-out duration-500 sm:duration-700",
              transition_leave_from: "translate-x-0",
              transition_leave_to: "translate-x-full"
            }
          ) do
            # Main container
            div(class: "relative flex h-full flex-col bg-white shadow-xl dark:bg-gray-800") do
              # Header with title and close button
              div(class: "bg-gradient-admin px-4 py-6 sm:px-6") do
                div(class: "flex items-center justify-between") do
                  h2(class: "text-base font-semibold text-white", id: "slideover-title") do
                    plain @title
                  end
                  div(class: "ml-3 flex h-7 items-center") do
                    button(
                      type: "button",
                      data: {action: "click->toggle#toggle touch->toggle#toggle"},
                      class: "relative rounded-md text-white/80 hover:text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
                    ) do
                      span(class: "absolute -inset-2.5")
                      span(class: "sr-only") { "Close panel" }
                      # SVG close icon
                      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "1.5", aria_hidden: "true", class: "size-6") do
                        path(d: "M6 18 18 6M6 6l12 12", stroke_linecap: "round", stroke_linejoin: "round")
                      end
                    end
                  end
                end
              end

              # Scrollable content area
              div(class: "flex-1 overflow-y-auto") do
                if @content_html
                  raw(@content_html)
                elsif @content_block
                  instance_eval(@content_block)
                end
              end

              # Sticky footer (if footer content exists)
              if @footer_html || @footer_block
                div(class: "flex shrink-0 justify-end gap-x-3 border-t border-gray-200 px-4 py-4 dark:border-white/10") do
                  if @footer_html
                    raw(@footer_html)
                  elsif @footer_block
                    instance_eval(&@footer_block)
                  end
                end
              end
            end
          end
        end

        def footer(&block)
          if defined?(view_context) && view_context
            @footer_html = view_context.capture(&block)
          else
            @footer_block = block
          end
        end

        alias_method :with_footer, :footer

        private

        def default_attrs
          {
            id: "slideover",
            class: slideover_classes
          }
        end

        def slideover_classes
          base = "ml-auto block size-full max-w-md transform absolute right-0 h-full z-50"
          visibility = @open ? "" : "hidden"
          [base, visibility].compact.join(" ")
        end
      end
    end
  end
end
