# frozen_string_literal: true

module Panda
  module Core
    class WidgetRegistry
      @widgets = []

      class << self
        attr_reader :widgets

        # Register a dashboard widget.
        # Duplicate labels are replaced (last registration wins).
        # @param label [String] Widget label (used for identification and deduplication)
        # @param component [Proc] Lambda receiving user, returns an instantiated component
        # @param visible [Proc, nil] Lambda receiving user, hides widget when false
        # @param position [Integer] Sort order (lower numbers appear first)
        def register(label, component:, visible: nil, position: 0)
          widget = {label: label, component: component, visible: visible, position: position}
          if (index = @widgets.index { |w| w[:label] == label })
            @widgets[index] = widget
          else
            @widgets << widget
          end
        end

        # Build the widget list for the current user.
        # Combines the legacy admin_dashboard_widgets lambda with registered widgets.
        # @param user [Object] The current user
        # @return [Array] Instantiated widget components
        def build(user)
          # Legacy backward-compatible widgets from the lambda
          legacy = Panda::Core.config.admin_dashboard_widgets&.call(user) || []

          # Registered widgets — filter by visibility, sort by position, instantiate
          registered = @widgets
            .select { |w| w[:visible].nil? || w[:visible].call(user) }
            .sort_by { |w| w[:position] }
            .map { |w| w[:component].call(user) }

          legacy + registered
        end

        # Clear all registrations (for test isolation).
        def reset!
          @widgets = []
        end
      end
    end
  end
end
