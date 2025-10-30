# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class HeadingComponent < Panda::Core::Base
        prop :text, String
        prop :level, _Nilable(_Union(Integer, Symbol)), default: -> { 2 }
        prop :icon, String, default: ""
        prop :additional_styles, _Nilable(_Union(String, Array)), default: -> { "" }

        def view_template(&block)
          # Capture any buttons defined via block
          instance_eval(&block) if block_given?

          case @level
          when 1
            h1(class: heading_classes) { render_content }
          when 2
            h2(class: heading_classes) { render_content }
          when 3
            h3(class: heading_classes) { render_content }
          when :panel
            h3(class: panel_heading_classes) { render_content }
          else
            h2(class: heading_classes) { render_content }
          end
        end

        def button(**props)
          @buttons ||= []
          @buttons << Panda::Core::Admin::ButtonComponent.new(**props)
        end

        private

        def render_content
          div(class: "grow") { @text }

          if @buttons&.any?
            span(class: "actions flex gap-x-2 -mt-1") do
              @buttons.each { |btn| render(btn) }
            end
          end
        end

        def heading_classes
          base = "flex pt-1 text-black mb-5 -mt-1"
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
          "text-base font-medium p-4 text-white"
        end

        def additional_styles_array
          return [] if @additional_styles.blank?
          @additional_styles.is_a?(String) ? @additional_styles.split(" ") : @additional_styles
        end
      end
    end
  end
end
