# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FormSelectComponent < Panda::Core::Base
        prop :name, String
        prop :options, Array
        prop :selected, _Nilable(_Union(String, Integer)), default: -> {}
        prop :prompt, _Nilable(String), default: -> {}
        prop :required, _Boolean, default: -> { false }
        prop :disabled, _Boolean, default: -> { false }
        prop :include_blank, _Boolean, default: -> { false }

        def view_template
          select(**@attrs) do
            render_prompt if @prompt
            render_blank if @include_blank && !@prompt
            render_options
          end
        end

        def default_attrs
          base_attrs = {
            name: @name,
            id: @name.to_s.gsub(/[\[\]]/, "_").gsub("__", "_").chomp("_"),
            class: select_classes
          }

          base_attrs[:required] = true if @required
          base_attrs[:disabled] = true if @disabled

          base_attrs
        end

        private

        def select_classes
          classes = "block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset focus:ring-2 focus:ring-inset sm:leading-6"

          if @disabled
            classes + " ring-gray-300 focus:ring-gray-300 bg-gray-50 cursor-not-allowed"
          else
            classes + " ring-primary-400 focus:ring-primary-600 hover:cursor-pointer"
          end
        end

        def render_prompt
          option(value: "", disabled: true, selected: @selected.nil?) { @prompt }
        end

        def render_blank
          option(value: "") { "" }
        end

        def render_options
          @options.each do |option_data|
            label, value = option_data
            option_attrs = {value: value.to_s}
            option_attrs[:selected] = true if value.to_s == @selected.to_s

            option(**option_attrs) { label.to_s }
          end
        end
      end
    end
  end
end
