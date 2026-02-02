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
          # Execute block if passed to new() directly (for tests/direct instantiation)
          # This allows: HeadingComponent.new(text: "Pages") { |h| h.with_button(...) }
          # Note: When used via render() with a block, ViewComponent handles the block separately
          yield self if block_given?
        end

        attr_reader :text, :icon, :meta, :level

        private

        def heading_classes
          margin_bottom = @meta.present? ? "mb-0.5" : "mb-5"
          base = "flex items-center gap-2 text-gray-900 #{margin_bottom}"
          styles = case @level
          when 1
            "text-2xl font-semibold"
          when 2
            "text-xl font-semibold"
          when 3
            "text-lg font-medium"
          else
            "text-xl font-semibold"
          end

          [base, styles, @additional_styles].compact.join(" ")
        end
      end
    end
  end
end
