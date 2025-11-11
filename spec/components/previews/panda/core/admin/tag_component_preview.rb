# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Tag
      class TagComponentPreview < Lookbook::Preview
        # Default tag
        # @label Default
        def default
          render Panda::Core::Admin::TagComponent.new do
            "Status"
          end
        end

        # Multiple tags showing common use cases
        # @label Multiple Tags
        def multiple
          render_inline Panda::Core::Admin::TagComponent.new { "Published" }
          render_inline " "
          render_inline Panda::Core::Admin::TagComponent.new { "Draft" }
          render_inline " "
          render_inline Panda::Core::Admin::TagComponent.new { "Archived" }
        end

        # Tag with longer text
        # @label Long Text
        def long_text
          render Panda::Core::Admin::TagComponent.new do
            "Work In Progress"
          end
        end
      end
    end
  end
end
