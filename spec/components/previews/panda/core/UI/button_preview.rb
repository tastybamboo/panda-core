# frozen_string_literal: true

module Panda
  module Core
    module UI
      # Modern Phlex Button Component
      #
      # This is an example of a modern Phlex-based component using the shared
      # Panda::Core::Base foundation. It demonstrates type-safe props, Tailwind
      # class merging, and clean component architecture.
      #
      # ## Features
      # - Type-safe properties via Literal
      # - Multiple variants (primary, secondary, success, danger, ghost)
      # - Three sizes (small, medium, large)
      # - Disabled state support
      # - Automatic Tailwind class conflict resolution
      #
      # ## Usage
      # ```ruby
      # render Panda::Core::UI::Button.new(
      #   text: "Click me",
      #   variant: :primary,
      #   size: :medium
      # )
      # ```
      #
      # @label Button (Phlex)
      # @display bg_color "#f9fafb"
      # @display viewport_width "400px"
      class ButtonPreview < Lookbook::Preview
        # @!group Basic Variants

        # Default gray button
        # @label Default
        def default
          render Panda::Core::UI::Button.new(text: "Default Button")
        end

        # Primary action button with blue styling
        #
        # Use this for the main call-to-action on a page or form.
        # @label Primary
        def primary
          render Panda::Core::UI::Button.new(
            text: "Primary Button",
            variant: :primary
          )
        end

        # Secondary button with white background
        #
        # Use for secondary actions that complement the primary button.
        # @label Secondary
        def secondary
          render Panda::Core::UI::Button.new(
            text: "Secondary Button",
            variant: :secondary
          )
        end

        # Success button with green styling
        #
        # Use for positive confirmation actions like "Save" or "Complete".
        # @label Success
        def success
          render Panda::Core::UI::Button.new(
            text: "Success Button",
            variant: :success
          )
        end

        # Danger button with red styling
        #
        # Use for destructive actions like "Delete" or "Remove".
        # Requires user confirmation for critical operations.
        # @label Danger
        def danger
          render Panda::Core::UI::Button.new(
            text: "Delete Item",
            variant: :danger
          )
        end

        # Ghost button with transparent background
        #
        # Use for tertiary actions or in dense interfaces.
        # @label Ghost
        def ghost
          render Panda::Core::UI::Button.new(
            text: "Ghost Button",
            variant: :ghost
          )
        end

        # @!endgroup

        # @!group Sizes

        # Small button for compact interfaces
        # @label Small Size
        def small_size
          render Panda::Core::UI::Button.new(
            text: "Small Button",
            variant: :primary,
            size: :small
          )
        end

        # Medium button (default size)
        # @label Medium Size
        def medium_size
          render Panda::Core::UI::Button.new(
            text: "Medium Button",
            variant: :primary,
            size: :medium
          )
        end

        # Large button for emphasis
        # @label Large Size
        def large_size
          render Panda::Core::UI::Button.new(
            text: "Large Button",
            variant: :primary,
            size: :large
          )
        end

        # Compare all three sizes side by side
        # @label Size Comparison
        def size_comparison
          render_inline Panda::Core::UI::Button.new(
            text: "Small",
            variant: :primary,
            size: :small
          )
          render_inline Panda::Core::UI::Button.new(
            text: "Medium",
            variant: :primary,
            size: :medium
          )
          render_inline Panda::Core::UI::Button.new(
            text: "Large",
            variant: :primary,
            size: :large
          )
        end

        # @!endgroup

        # @!group States

        # Button in disabled state
        #
        # Disabled buttons are not interactive and appear dimmed.
        # @label Disabled
        def disabled
          render Panda::Core::UI::Button.new(
            text: "Disabled Button",
            variant: :primary,
            disabled: true
          )
        end

        # Compare enabled vs disabled state
        # @label Enabled vs Disabled
        def enabled_vs_disabled
          render_inline Panda::Core::UI::Button.new(
            text: "Enabled",
            variant: :primary
          )
          render_inline Panda::Core::UI::Button.new(
            text: "Disabled",
            variant: :primary,
            disabled: true
          )
        end

        # @!endgroup

        # @!group As Links

        # Button rendered as a link with href
        #
        # When an href is provided, the button renders as an <a> tag
        # instead of a <button> tag, perfect for navigation.
        # @label Link Button
        def as_link
          render Panda::Core::UI::Button.new(
            text: "Go to Dashboard",
            variant: :primary,
            href: "/admin/dashboard"
          )
        end

        # Secondary button as link
        # @label Secondary Link
        def secondary_link
          render Panda::Core::UI::Button.new(
            text: "View Details",
            variant: :secondary,
            href: "/admin/details"
          )
        end

        # Compare button and link side by side
        # @label Button vs Link
        def button_vs_link
          render_inline Panda::Core::UI::Button.new(
            text: "Submit Form",
            variant: :primary,
            type: "submit"
          )
          render_inline Panda::Core::UI::Button.new(
            text: "Go to Page",
            variant: :primary,
            href: "/admin/page"
          )
        end

        # @!endgroup

        # @!group Advanced

        # Button with custom CSS classes
        #
        # Demonstrates Tailwind class merging - custom classes are
        # intelligently merged with component defaults.
        # @label With Custom Classes
        def custom_classes
          render Panda::Core::UI::Button.new(
            text: "Custom Styled",
            variant: :primary,
            class: "mt-4 shadow-xl"
          )
        end

        # Button with data attributes
        #
        # Shows how to add Turbo/Stimulus data attributes.
        # @label With Data Attributes
        def with_data_attributes
          render Panda::Core::UI::Button.new(
            text: "Turbo Button",
            variant: :danger,
            data: {
              turbo_method: :delete,
              turbo_confirm: "Are you sure?",
              controller: "button"
            }
          )
        end

        # Submit button type
        #
        # Change the button type for form submissions.
        # @label Submit Type
        def submit_type
          render Panda::Core::UI::Button.new(
            text: "Submit Form",
            variant: :success,
            type: "submit"
          )
        end

        # @!endgroup

        # @!group Playground

        # Interactive playground to test all button variations
        #
        # Experiment with different combinations of props to see how
        # the button adapts. This is useful for testing edge cases
        # and finding the right combination for your use case.
        #
        # @label Interactive Playground
        # @param text text "Button text"
        # @param variant select { choices: [default, primary, secondary, success, danger, ghost] }
        # @param size select { choices: [small, medium, large] }
        # @param disabled toggle "Disabled state"
        # @param type select { choices: [button, submit, reset] }
        def playground(
          text: "Click Me",
          variant: "primary",
          size: "medium",
          disabled: false,
          type: "button"
        )
          render Panda::Core::UI::Button.new(
            text: text,
            variant: variant.to_sym,
            size: size.to_sym,
            disabled: disabled,
            type: type
          )
        end

        # @!endgroup
      end
    end
  end
end
