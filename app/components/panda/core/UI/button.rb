# frozen_string_literal: true

module Panda
  module Core
    module UI
      # Modern Phlex-based button component with type-safe props.
      #
      # This component demonstrates the recommended pattern for building
      # Phlex components in the Panda ecosystem using the shared base class.
      #
      # @example Basic usage
      #   render Panda::Core::UI::Button.new(text: "Click me")
      #
      # @example With variant
      #   render Panda::Core::UI::Button.new(
      #     text: "Delete",
      #     variant: :danger,
      #     size: :large
      #   )
      #
      # @example With custom attributes
      #   render Panda::Core::UI::Button.new(
      #     text: "Submit",
      #     variant: :primary,
      #     class: "mt-4",
      #     data: { turbo_method: :post }
      #   )
      #
      class Button < Panda::Core::Base
        # Type-safe properties using Literal
        prop :text, String
        prop :variant, Symbol, default: :default
        prop :size, Symbol, default: :medium
        prop :disabled, _Boolean, default: false
        prop :type, String, default: "button"

        def view_template
          button(**@attrs) { text }
        end

        def default_attrs
          {
            type: type,
            disabled: disabled,
            class: button_classes
          }
        end

        private

        def button_classes
          base = "inline-flex items-center rounded-md font-medium shadow-sm transition-colors"
          base += " #{size_classes}"
          base += " #{variant_classes}"
          base += " disabled:opacity-50 disabled:cursor-not-allowed" if disabled
          base
        end

        def size_classes
          case size
          when :small, :sm
            "gap-x-1.5 px-2.5 py-1.5 text-sm"
          when :large, :lg
            "gap-x-2 px-3.5 py-2.5 text-lg"
          else # :medium, :md
            "gap-x-1.5 px-3 py-2 text-base"
          end
        end

        def variant_classes
          case variant
          when :primary
            "bg-blue-600 text-white hover:bg-blue-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
          when :secondary
            "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          when :success
            "bg-green-600 text-white hover:bg-green-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-green-600"
          when :danger
            "bg-red-600 text-white hover:bg-red-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
          when :ghost
            "bg-transparent text-gray-700 hover:bg-gray-100"
          else # :default
            "bg-gray-700 text-white hover:bg-gray-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-700"
          end
        end
      end
    end
  end
end
