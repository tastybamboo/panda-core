# frozen_string_literal: true

module Panda
  module Core
    module UI
      # Badge Component for Status and Labels
      #
      # Badges are small, inline elements used to display statuses, counts,
      # or labels. They help users quickly identify important information
      # at a glance.
      #
      # ## When to use
      # - Status indicators (Active, Pending, Completed)
      # - Category labels
      # - Notification counts
      # - Feature flags or tags
      #
      # ## Accessibility
      # - Uses semantic HTML (span)
      # - Includes proper ARIA labels for removable badges
      # - Sufficient color contrast for all variants
      #
      # @label Badge (Phlex)
      # @tags stable
      class BadgePreview < Lookbook::Preview
        # @!group Variants

        # Default neutral badge
        # @label Default
        def default
          render Panda::Core::UI::Badge.new(text: "Default")
        end

        # Primary badge for main categories or features
        # @label Primary
        def primary
          render Panda::Core::UI::Badge.new(
            text: "Primary",
            variant: :primary
          )
        end

        # Success badge for positive states
        #
        # Examples: "Active", "Completed", "Published"
        # @label Success
        def success
          render Panda::Core::UI::Badge.new(
            text: "Active",
            variant: :success
          )
        end

        # Warning badge for cautionary states
        #
        # Examples: "Pending", "Draft", "Review Required"
        # @label Warning
        def warning
          render Panda::Core::UI::Badge.new(
            text: "Pending",
            variant: :warning
          )
        end

        # Danger badge for error or critical states
        #
        # Examples: "Error", "Failed", "Rejected"
        # @label Danger
        def danger
          render Panda::Core::UI::Badge.new(
            text: "Error",
            variant: :danger
          )
        end

        # Info badge for informational states
        #
        # Examples: "New", "Beta", "Updated"
        # @label Info
        def info
          render Panda::Core::UI::Badge.new(
            text: "New",
            variant: :info
          )
        end

        # All variants displayed together
        # @label All Variants
        # @display layout "centered"
        def all_variants
          render_inline Panda::Core::UI::Badge.new(text: "Default")
          render_inline Panda::Core::UI::Badge.new(text: "Primary", variant: :primary)
          render_inline Panda::Core::UI::Badge.new(text: "Success", variant: :success)
          render_inline Panda::Core::UI::Badge.new(text: "Warning", variant: :warning)
          render_inline Panda::Core::UI::Badge.new(text: "Danger", variant: :danger)
          render_inline Panda::Core::UI::Badge.new(text: "Info", variant: :info)
        end

        # @!endgroup

        # @!group Sizes

        # Small badge for compact displays
        # @label Small
        def small
          render Panda::Core::UI::Badge.new(
            text: "Small",
            size: :small,
            variant: :primary
          )
        end

        # Medium badge (default size)
        # @label Medium
        def medium
          render Panda::Core::UI::Badge.new(
            text: "Medium",
            size: :medium,
            variant: :primary
          )
        end

        # Large badge for emphasis
        # @label Large
        def large
          render Panda::Core::UI::Badge.new(
            text: "Large",
            size: :large,
            variant: :primary
          )
        end

        # Size comparison
        # @label Size Comparison
        def size_comparison
          render_inline Panda::Core::UI::Badge.new(
            text: "Small",
            size: :small,
            variant: :success
          )
          render_inline Panda::Core::UI::Badge.new(
            text: "Medium",
            size: :medium,
            variant: :success
          )
          render_inline Panda::Core::UI::Badge.new(
            text: "Large",
            size: :large,
            variant: :success
          )
        end

        # @!endgroup

        # @!group Shapes

        # Rounded corners (default)
        # @label Rounded
        def rounded
          render Panda::Core::UI::Badge.new(
            text: "Rounded",
            variant: :primary,
            rounded: false
          )
        end

        # Fully rounded (pill shape)
        #
        # Great for counts or compact labels
        # @label Pill Shape
        def pill
          render Panda::Core::UI::Badge.new(
            text: "Pill",
            variant: :primary,
            rounded: true
          )
        end

        # @!endgroup

        # @!group Interactive

        # Badge with remove button
        #
        # Useful for tags or filters that users can remove.
        # Click the X icon to trigger the removal action.
        # @label Removable
        def removable
          render Panda::Core::UI::Badge.new(
            text: "JavaScript",
            variant: :primary,
            removable: true
          )
        end

        # Multiple removable badges
        #
        # Common pattern for tag lists or active filters
        # @label Tag List
        def tag_list
          render_inline Panda::Core::UI::Badge.new(
            text: "Ruby",
            variant: :danger,
            removable: true,
            rounded: true
          )
          render_inline Panda::Core::UI::Badge.new(
            text: "Rails",
            variant: :success,
            removable: true,
            rounded: true
          )
          render_inline Panda::Core::UI::Badge.new(
            text: "Phlex",
            variant: :info,
            removable: true,
            rounded: true
          )
        end

        # @!endgroup

        # @!group Real-World Examples

        # Notification badge with count
        # @label Notification Count
        def notification_count
          render Panda::Core::UI::Badge.new(
            text: "3",
            variant: :danger,
            size: :small,
            rounded: true
          )
        end

        # Status badges for different states
        # @label Status Indicators
        def status_indicators
          render_inline Panda::Core::UI::Badge.new(text: "Shipped", variant: :success)
          render_inline Panda::Core::UI::Badge.new(text: "Pending", variant: :warning)
          render_inline Panda::Core::UI::Badge.new(text: "Active", variant: :success)
        end

        # @!endgroup

        # @!group Playground

        # Interactive playground for testing badge variations
        #
        # @label Playground
        # @param text text "Badge text"
        # @param variant select { choices: [default, primary, success, warning, danger, info] }
        # @param size select { choices: [small, medium, large] }
        # @param rounded toggle "Pill shape"
        # @param removable toggle "Show remove button"
        def playground(
          text: "Badge",
          variant: "primary",
          size: "medium",
          rounded: false,
          removable: false
        )
          render Panda::Core::UI::Badge.new(
            text: text,
            variant: variant.to_sym,
            size: size.to_sym,
            rounded: rounded,
            removable: removable
          )
        end

        # @!endgroup
      end
    end
  end
end
