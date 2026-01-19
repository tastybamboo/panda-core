# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class HeadingComponent < Panda::Core::Base
        renders_many :buttons, lambda { |text: "Button", action: nil, href: "#", icon: nil, size: :regular, id: nil, as_button: false, **attrs|
          Panda::Core::Admin::ButtonComponent.new(text: text, action: action, href: href, icon: icon, size: size, id: id, as_button: as_button, **attrs)
        }

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
