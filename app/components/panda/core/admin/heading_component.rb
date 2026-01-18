# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class HeadingComponent < Panda::Core::Base
    def initialize(text: "", icon: "", meta: nil, **attrs)
    @text = text
    @icon = icon
    @meta = meta
      super(**attrs)
    end

    attr_reader :text, :icon, :meta

        def before_render
          # Capture any buttons defined via block
          instance_eval(&content) if content.present?
        end

        def button(**props)
          @buttons ||= []
          @buttons << Panda::Core::Admin::ButtonComponent.new(**props)
        end

        private

        def render_content
          content_tag(:div, class: "grow flex items-center gap-x-2") do
            icon_html = @icon.present? ? content_tag(:i, "", class: @icon) : ""
            text_html = content_tag(:span, @text)
            (icon_html + text_html).html_safe
          end +
          content_tag(:span, class: "actions flex gap-x-2 mt-1 min-h-[2.5rem]") do
            safe_join(@buttons&.map { |btn| render(btn) } || [])
          end
        end

        def heading_classes(has_meta = false)
          margin_bottom = has_meta ? "mb-0.5" : "mb-5"
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

          [base, styles, *additional_styles_array].compact.join(" ")
        end

        def panel_heading_classes
          "text-base font-medium px-4 py-3 text-white"
        end

        def additional_styles_array
          return [] if @additional_styles.blank?
          @additional_styles.is_a?(String) ? @additional_styles.split(" ") : @additional_styles
        end
      end
    end
  end
end
