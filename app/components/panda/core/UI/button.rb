# frozen_string_literal: true

module Panda
  module Core
    module UI
      # Modern Phlex-based button component with type-safe props.
      #
      # Supports both <button> and <a> elements based on whether an href is provided.
      # Follows Tailwind UI Plus styling patterns with dark mode support.
      #
      # @example Basic button
      #   render Panda::Core::UI::Button.new(text: "Click me")
      #
      # @example Button as link
      #   render Panda::Core::UI::Button.new(
      #     text: "Edit",
      #     variant: :secondary,
      #     href: "/admin/posts/1/edit"
      #   )
      #
      # @example Primary action button
      #   render Panda::Core::UI::Button.new(
      #     text: "Publish",
      #     variant: :primary,
      #     href: "/admin/posts/1/publish"
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
        def initialize(text: "", variant: :default, size: :medium, disabled: false, type: "button", href: nil, **attrs)
          @text = text
          @variant = variant
          @size = size
          @disabled = disabled
          @type = type
          @href = href
          super(**attrs)
        end

        attr_reader :text, :variant, :size, :disabled, :type, :href

        def default_attrs
          base = {
            class: button_classes
          }

          if @href
            base[:href] = @href
          else
            base[:type] = @type
            base[:disabled] = @disabled if @disabled
          end

          base
        end

        private

        def button_classes
          base = "inline-flex items-center rounded-md font-semibold"
          base += " #{size_classes}"
          base += " #{variant_classes}"
          base += " disabled:opacity-50 disabled:cursor-not-allowed" if @disabled
          base
        end

        def size_classes
          case @size
          when :small, :sm
            "px-2.5 py-1.5 text-sm"
          when :large, :lg
            "px-3.5 py-2.5 text-lg"
          else # :medium, :md
            "px-3 py-2 text-sm"
          end
        end

        def variant_classes
          case @variant
          when :primary
            # Primary button with dark mode support
            "bg-primary-500 text-white shadow-xs hover:bg-primary-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600 dark:bg-primary-400 dark:shadow-none dark:hover:bg-primary-500 dark:focus-visible:outline-primary-500"
          when :secondary
            # White/gray secondary button with ring and dark mode support
            "bg-white text-gray-900 shadow-xs inset-ring inset-ring-gray-300 hover:bg-gray-50 dark:bg-white/10 dark:text-white dark:shadow-none dark:inset-ring-white/5 dark:hover:bg-white/20"
          when :success
            "bg-success-600 text-white shadow-xs hover:bg-success-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-success-600 dark:bg-success-500 dark:shadow-none dark:hover:bg-success-600 dark:focus-visible:outline-success-500"
          when :danger
            "bg-error-600 text-white shadow-xs hover:bg-error-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-error-600 dark:bg-error-500 dark:shadow-none dark:hover:bg-error-600 dark:focus-visible:outline-error-500"
          when :ghost
            "bg-transparent text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
          else # :default
            "bg-gray-700 text-white shadow-xs hover:bg-gray-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-700 dark:bg-gray-600 dark:shadow-none dark:hover:bg-gray-500 dark:focus-visible:outline-gray-600"
          end
        end
      end
    end
  end
end
