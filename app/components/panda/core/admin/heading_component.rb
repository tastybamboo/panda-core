# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class HeadingComponent < Panda::Core::Base
        prop :text, String
        prop :level, _Nilable(_Union(Integer, Symbol)), default: -> { 2 }
        prop :icon, String, default: ""
        prop :meta, _Nilable(String), default: -> {}
        prop :additional_styles, _Nilable(_Union(String, Array)), default: -> { "" }

        def view_template(&block)
          # Capture any buttons defined via block
          instance_eval(&block) if block_given?

          div(class: "heading-wrapper") do
            case @level
            when 1
              h1(class: heading_classes(@meta.present?)) { render_content }
            when 2
              h2(class: heading_classes(@meta.present?)) { render_content }
            when 3
              h3(class: heading_classes(@meta.present?)) { render_content }
            when :panel
              h3(class: panel_heading_classes) { @text }
            else
              h2(class: heading_classes(@meta.present?)) { render_content }
            end

            if @meta
              p(class: "text-sm text-black/60 -mt-1 mb-5") { raw(@meta) }
            end
          end
        end

        def button(**props)
          @buttons ||= []
          @buttons << Panda::Core::Admin::ButtonComponent.new(**props)
        end

        private

        def render_content
          div(class: "grow flex items-center gap-x-2") do
            i(class: @icon) if @icon.present?
            span { @text }
          end

          span(class: "actions flex gap-x-2 mt-1 min-h-[2.5rem]") do
            @buttons&.each { |btn| render(btn) }
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
