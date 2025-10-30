# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Form Error
      # @tags stable
      class FormErrorComponentPreview < ViewComponent::Preview
        # Single error message
        # @label Single Error
        def single_error
          render Panda::Core::Admin::FormErrorComponent.new(
            errors: ["Name can't be blank"]
          )
        end

        # Multiple error messages
        # @label Multiple Errors
        def multiple_errors
          render Panda::Core::Admin::FormErrorComponent.new(
            errors: [
              "Name can't be blank",
              "Email is invalid",
              "Password is too short (minimum is 8 characters)"
            ]
          )
        end

        # No errors (component won't render)
        # @label No Errors
        def no_errors
          render_inline Panda::Core::Admin::FormErrorComponent.new(
            errors: []
          )
          render_inline '<div class="p-4 border border-gray-300 rounded-md">No errors to display - component does not render</div>'.html_safe
        end

        # With ActiveModel errors (simulated)
        # @label ActiveModel Errors
        def active_model_errors
          # Create a simple mock object with errors
          mock_model = Struct.new(:errors) do
            def errors
              errors_obj = Object.new
              def errors_obj.any?
                true
              end

              def errors_obj.full_messages
                [
                  "Title can't be blank",
                  "Content is too short",
                  "Published date must be in the future"
                ]
              end
              errors_obj
            end
          end.new(nil)

          render Panda::Core::Admin::FormErrorComponent.new(
            model: mock_model
          )
        end

        # Form validation example
        # @label Form with Validation
        def form_with_validation
          render_inline Panda::Core::Admin::FormErrorComponent.new(
            errors: [
              "Email has already been taken",
              "Password confirmation doesn't match Password"
            ]
          )
          render_inline '<div class="mt-4">'.html_safe
          render_inline Panda::Core::Admin::FormInputComponent.new(
            name: "user[email]",
            type: :email,
            value: "existing@example.com",
            placeholder: "Email"
          )
          render_inline "</div>".html_safe
        end
      end
    end
  end
end
