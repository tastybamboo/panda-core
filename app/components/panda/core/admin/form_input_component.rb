# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FormInputComponent < Panda::Core::Base
        def initialize(name: "", value: nil, placeholder: nil, autocomplete: nil, type: :text, required: false, disabled: false, **attrs)
          @name = name
          @value = value
          @type = type
          @placeholder = placeholder
          @required = required
          @disabled = disabled
          @autocomplete = autocomplete
          super(**attrs)
        end

        attr_reader :name, :value, :type, :placeholder, :required, :disabled, :autocomplete

        def default_attrs
          base_attrs = {
            type: @type.to_s,
            name: @name,
            id: @name.to_s.gsub(/[\[\]]/, "_").gsub("__", "_").chomp("_"),
            class: input_classes
          }

          base_attrs[:value] = @value if @value
          base_attrs[:placeholder] = @placeholder if @placeholder
          base_attrs[:required] = true if @required
          base_attrs[:disabled] = true if @disabled
          base_attrs[:autocomplete] = @autocomplete if @autocomplete

          base_attrs
        end

        private

        def input_classes
          classes = "block w-full rounded-md border-0 p-2 text-gray-900 ring-1 ring-inset placeholder:text-gray-400 focus:ring-2 focus:ring-inset sm:leading-6"

          if @disabled
            classes + " ring-gray-300 focus:ring-gray-300 bg-gray-50 cursor-not-allowed"
          else
            classes + " ring-primary-400 focus:ring-primary-600 hover:cursor-pointer"
          end
        end
      end
    end
  end
end
