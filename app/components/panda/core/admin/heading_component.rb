# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class HeadingComponent < Panda::Core::Base
        renders_many :buttons, "Panda::Core::Admin::ButtonComponent"

        def initialize(text: "", icon: "", meta: nil, level: 2, **attrs)
          @text = text
          @icon = icon
          @meta = meta
          @level = level
          super(**attrs)
        end

        attr_reader :text, :icon, :meta, :level

        private

        def heading_classes
          margin_bottom = @meta.present? ? "mb-0.5" : "mb-5"
          base = "flex text-black #{margin_bottom} -mt-2"
          styles = case @level
          when 1
            "text-2xl font-medium"
          when 2
            "text-xl font-medium"
          when 3
            "text-xl font-light"
          else
            "text-xl font-medium"
          end

          [base, styles].compact.join(" ")
        end
      end
    end
  end
end
