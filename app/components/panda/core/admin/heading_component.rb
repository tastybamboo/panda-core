# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class HeadingComponent < Panda::Core::Base
        renders_many :buttons, lambda { |text: "Button", action: nil, href: "#", icon: nil, size: :regular, id: nil, as_button: false, **attrs|
          Panda::Core::Admin::ButtonComponent.new(text: text, action: action, href: href, icon: icon, size: size, id: id, as_button: as_button, **attrs)
        }

        # Provide singular method for DSL-style usage
        def button(**args)
          buttons(**args)
        end

        def initialize(text: "", icon: "", meta: nil, level: 2, additional_styles: nil, **attrs, &block)
          @text = text
          @icon = icon
          @meta = meta
          @level = level
          @additional_styles = additional_styles
          super(**attrs)
          # Execute the block to allow DSL-style button definitions
          yield self if block_given?
        end

        attr_reader :text, :icon, :meta, :level

        private

        def heading_classes
          if @level == :panel
            # Panel headings have their own styling
            styles = "flex text-base font-medium px-4 py-3 text-white"
            [styles, @additional_styles].compact.join(" ")
          else
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
end
