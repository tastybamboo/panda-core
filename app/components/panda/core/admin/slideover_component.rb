# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SlideoverComponent < Panda::Core::Base
    def initialize(title: "Settings", open: false, **attrs)
    @title = title
    @open = open
      super(**attrs)
    end

    attr_reader :title, :open

    def before_render
      # Capture main content block if provided
      if content.present?
        if defined?(view_context) && view_context
          @content_html = view_context.capture { content.call }
        else
          @content_block = content
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

        def close_icon
          content_tag(:svg,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: "1.5",
            aria: {hidden: "true"},
            class: "size-6"
          ) do
            tag.path(
              d: "M6 18 18 6M6 6l12 12",
              stroke_linecap: "round",
              stroke_linejoin: "round"
            )
          end
        end
      end
    end
  end
end
