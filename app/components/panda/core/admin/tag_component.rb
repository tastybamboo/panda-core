# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TagComponent < Panda::Core::Base
    def initialize(status: :active, text:, page_type:, **attrs)
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
          base = "inline-flex items-center py-1 px-2 text-xs font-medium rounded-md ring-1 ring-inset "
          base + (@page_type ? type_classes : status_classes)
        end

        def type_classes
          case @page_type
          when :system
            "text-red-700 bg-red-100 ring-red-600/20 dark:bg-red-400/10 dark:text-red-400"
          when :posts
            "text-purple-700 bg-purple-100 ring-purple-600/20 dark:bg-purple-400/10 dark:text-purple-400"
          when :code
            "text-blue-700 bg-blue-100 ring-blue-600/20 dark:bg-blue-400/10 dark:text-blue-400"
          when :standard
            "text-green-700 bg-green-100 ring-green-600/20 dark:bg-green-400/10 dark:text-green-400"
          when :hidden_type
            "text-gray-700 bg-gray-100 ring-gray-600/20 dark:bg-gray-400/10 dark:text-gray-400"
          else
            "text-gray-700 bg-gray-100 ring-gray-600/20 dark:bg-gray-400/10 dark:text-gray-400"
          end
        end

        def status_classes
          case @status
          when :active
            "text-white ring-black/30 bg-green-600 border-0"
          when :draft
            "text-black ring-black/30 bg-yellow-400"
          when :inactive, :hidden
            "text-black ring-black/30 bg-black/5 bg-white"
          when :auto
            "text-blue-700 bg-blue-100 ring-blue-600/20 dark:bg-blue-400/10 dark:text-blue-400"
          when :static
            "text-gray-700 bg-gray-100 ring-gray-600/20 dark:bg-gray-400/10 dark:text-gray-400"
          else
            "text-black bg-white"
          end
        end
      end
    end
  end
end
