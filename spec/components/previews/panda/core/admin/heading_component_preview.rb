# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Heading
      class HeadingComponentPreview < Lookbook::Preview
        # Default heading
        # @label Default
        def default
          render Panda::Core::Admin::HeadingComponent.new(
            text: "Page Heading"
          )
        end

        # Heading with longer text
        # @label Long Text
        def long_text
          render Panda::Core::Admin::HeadingComponent.new(
            text: "This is a Much Longer Heading That Spans Multiple Words"
          )
        end

        # Multiple headings showing hierarchy
        # @label Hierarchy
        def hierarchy
          render_inline Panda::Core::Admin::HeadingComponent.new(text: "Main Section Heading")
          render_inline "<div class='mt-8'></div>".html_safe
          render_inline Panda::Core::Admin::HeadingComponent.new(text: "Subsection Heading")
        end
      end
    end
  end
end
