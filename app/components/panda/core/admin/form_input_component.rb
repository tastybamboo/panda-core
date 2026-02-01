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
          classes = "block w-full h-11 rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-gray-900 " \
                    "placeholder:text-gray-400 focus:border-transparent focus:ring-2 focus:ring-primary-500"

          if @disabled
            classes + " border-gray-200 bg-gray-100 text-gray-400 cursor-not-allowed"
          else
            classes
          end
        end
      end
    end
  end
end
