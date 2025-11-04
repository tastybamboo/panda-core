# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Flash Message Component (Tailwind Plus Style)
      #
      # Modern notification component based on Tailwind UI Plus patterns.
      # Features dark mode support, FontAwesome icons, and optional subtitles.
      #
      # @label Flash Message
      class FlashMessageComponentPreview < ViewComponent::Preview
        # Notice message (informational)
        # @label Notice
        def notice
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :notice,
            message: "Your changes have been saved successfully."
          )
        end

        # Success message with subtitle
        # @label Success
        def success
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :success,
            message: "Successfully saved!",
            subtitle: "Anyone with a link can now view this file."
          )
        end

        # Warning message
        # @label Warning
        def warning
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :warning,
            message: "This action requires confirmation",
            subtitle: "Please review your input before proceeding."
          )
        end

        # Alert/error message
        # @label Alert
        def alert
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :alert,
            message: "Action failed",
            subtitle: "Please check your input and try again."
          )
        end

        # Error message
        # @label Error
        def error
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :error,
            message: "An error occurred",
            subtitle: "Unable to process your request. Please try again later."
          )
        end

        # Info message (alias for notice)
        # @label Info
        def info
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :info,
            message: "Your profile has been updated",
            subtitle: "Changes will be visible to other users within 5 minutes."
          )
        end

        # Long message to test wrapping
        # @label Long Message
        def long_message
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :notice,
            message: "This is a much longer flash message that contains more detailed information about what just happened. It should wrap properly and maintain readability across multiple lines.",
            subtitle: "Additional context can be provided in the subtitle which also supports longer text that may wrap to multiple lines."
          )
        end

        # Without subtitle (simple notification)
        # @label Simple (No Subtitle)
        def simple
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :success,
            message: "Operation completed successfully!"
          )
        end

        # Interactive playground
        # @label Playground
        # @param kind select { choices: [notice, success, alert, error, warning, info] }
        # @param message text "Message text"
        # @param subtitle text "Optional subtitle"
        def playground(kind: "success", message: "Your custom message here", subtitle: "")
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: kind.to_sym,
            message: message,
            subtitle: subtitle.present? ? subtitle : nil
          )
        end
      end
    end
  end
end
