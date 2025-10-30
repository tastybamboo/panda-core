# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TagComponent < Panda::Core::Base
        prop :status, Symbol, default: :active
        prop :text, _Nilable(String), default: -> {}

        def view_template
          span(class: tag_classes) { computed_text }
        end

        private

        def computed_text
          @text || @status.to_s.humanize
        end

        def tag_classes
          base = "inline-flex items-center py-1 px-2 text-xs font-medium rounded-md ring-1 ring-inset "
          base + status_classes
        end

        def status_classes
          case @status
          when :active
            "text-white ring-black/30 bg-green-600 border-0"
          when :draft
            "text-black ring-black/30 bg-yellow-400"
          when :inactive, :hidden
            "text-black ring-black/30 bg-black/5 bg-white"
          else
            "text-black bg-white"
          end
        end
      end
    end
  end
end
