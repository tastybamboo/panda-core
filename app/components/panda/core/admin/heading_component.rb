# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class HeadingComponent < Panda::Core::Base
        renders_many :buttons, Panda::Core::Admin::ButtonComponent

        def initialize(text: "", icon: "", meta: nil, level: 2, additional_styles: nil, **attrs, &block)
          @text = text
          @icon = icon
          @meta = meta
          @level = level
          @additional_styles = additional_styles
          super(**attrs)
          # Execute the block to register buttons via DSL (for direct usage)
          # Note: When used via ContainerComponent's heading_slot, the block is NOT passed here
          # to prevent double execution (ViewComponent also yields to the block)
          yield self if block_given?
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

          [base, styles, @additional_styles].compact.join(" ")
        end
      end
    end
  end
end
