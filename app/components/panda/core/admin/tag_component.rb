# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TagComponent < Panda::Core::Base
        def initialize(text: nil, page_type: nil, status: :active, **attrs)
          @status = status
          @text = text
          @page_type = page_type
          super(**attrs)
        end

        attr_reader :status, :text, :page_type

        def computed_text
          if @page_type
            @text || type_display_text
          else
            @text || @status.to_s.humanize
          end
        end

        def type_display_text
          case @page_type
          when :standard
            "Active"
          when :hidden_type
            "Hidden"
          else
            @page_type.to_s.humanize
          end
        end

        def tag_classes
          base = "inline-flex items-center px-2.5 py-0.5 text-xs font-medium rounded-full "
          base + (@page_type ? type_classes : status_classes)
        end

        def type_classes
          case @page_type
          when :system
            "text-rose-600 bg-rose-50"
          when :posts
            "text-sky-600 bg-sky-50"
          when :code
            "text-sky-600 bg-sky-50"
          when :standard
            "text-emerald-600 bg-emerald-50"
          when :hidden_type
            "text-gray-600 bg-gray-100"
          else
            "text-gray-600 bg-gray-100"
          end
        end

        def status_classes
          case @status
          when :active
            "text-emerald-600 bg-emerald-50"
          when :live
            "text-emerald-600 bg-emerald-50"
          when :draft
            "text-amber-600 bg-amber-50"
          when :inactive, :hidden
            "text-gray-600 bg-gray-100"
          when :auto
            "text-sky-600 bg-sky-50"
          when :static
            "text-gray-600 bg-gray-100"
          else
            "text-gray-600 bg-gray-100"
          end
        end
      end
    end
  end
end
