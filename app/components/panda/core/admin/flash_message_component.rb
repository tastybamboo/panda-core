# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FlashMessageComponent < ::ViewComponent::Base
        attr_reader :kind, :message

        def initialize(message:, kind:, temporary: true)
          @kind = kind.to_sym
          @message = message
          @temporary = temporary
        end

        def text_colour_css
          case kind
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
          case kind
          when :success
            "fa-circle-check"
          when :alert
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
