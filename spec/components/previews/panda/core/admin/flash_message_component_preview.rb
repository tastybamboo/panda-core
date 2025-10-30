# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Flash Message
      # @tags stable
      class FlashMessageComponentPreview < ViewComponent::Preview
        # Notice message (informational)
        # @label Notice
        def notice
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :notice,
            message: "Your changes have been saved successfully."
          )
        end

        # Success message
        # @label Success
        def success
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :success,
            message: "Operation completed successfully!"
          )
        end

        # Alert/warning message
        # @label Alert
        def alert
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :alert,
            message: "Please review your input before proceeding."
          )
        end

        # Error message
        # @label Error
        def error
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :error,
            message: "An error occurred. Please try again."
          )
        end

        # Long message to test wrapping
        # @label Long Message
        def long_message
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: :notice,
            message: "This is a much longer flash message that contains more detailed information about what just happened. It should wrap properly and maintain readability across multiple lines."
          )
        end

        # Interactive playground
        # @label Playground
        # @param kind select { choices: [notice, success, alert, error] }
        # @param message text "Message text"
        def playground(kind: "notice", message: "Your custom message here")
          render Panda::Core::Admin::FlashMessageComponent.new(
            kind: kind.to_sym,
            message: message
          )
        end
      end
    end
  end
end
