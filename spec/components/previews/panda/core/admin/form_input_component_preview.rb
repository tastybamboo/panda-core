# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Form Input
      class FormInputComponentPreview < Lookbook::Preview
        # Default text input
        # @label Text Input
        def text_input
          render Panda::Core::Admin::FormInputComponent.new(
            name: "user[name]",
            type: :text,
            placeholder: "Enter your name"
          )
        end

        # Email input field
        # @label Email Input
        def email_input
          render Panda::Core::Admin::FormInputComponent.new(
            name: "user[email]",
            type: :email,
            placeholder: "email@example.com"
          )
        end

        # Password input field
        # @label Password Input
        def password_input
          render Panda::Core::Admin::FormInputComponent.new(
            name: "user[password]",
            type: :password,
            placeholder: "Enter password"
          )
        end

        # Date input field
        # @label Date Input
        def date_input
          render Panda::Core::Admin::FormInputComponent.new(
            name: "event[date]",
            type: :date
          )
        end

        # Datetime input field
        # @label Datetime Input
        def datetime_input
          render Panda::Core::Admin::FormInputComponent.new(
            name: "event[datetime]",
            type: :"datetime-local"
          )
        end

        # Input with value
        # @label With Value
        def with_value
          render Panda::Core::Admin::FormInputComponent.new(
            name: "post[title]",
            type: :text,
            value: "Example Title",
            placeholder: "Post title"
          )
        end

        # Required input field
        # @label Required Field
        def required_field
          render Panda::Core::Admin::FormInputComponent.new(
            name: "user[name]",
            type: :text,
            placeholder: "Required field",
            required: true
          )
        end

        # Disabled input field
        # @label Disabled Field
        def disabled_field
          render Panda::Core::Admin::FormInputComponent.new(
            name: "user[name]",
            type: :text,
            value: "Cannot edit this",
            disabled: true
          )
        end

        # Interactive playground
        # @label Playground
        # @param name text "Field name"
        # @param type select { choices: [text, email, password, date, datetime-local, tel, url] }
        # @param placeholder text "Placeholder text"
        # @param value text "Field value (optional)"
        # @param required toggle
        # @param disabled toggle
        def playground(name: "field[name]", type: "text", placeholder: "Enter value", value: nil, required: false, disabled: false)
          render Panda::Core::Admin::FormInputComponent.new(
            name: name,
            type: type.to_sym,
            placeholder: placeholder.presence,
            value: value.presence,
            required: required,
            disabled: disabled
          )
        end
      end
    end
  end
end
