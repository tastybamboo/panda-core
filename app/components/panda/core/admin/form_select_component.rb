# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FormSelectComponent < Panda::Core::Base
        def initialize(prompt:, name: "", options: [], required: false, disabled: false, include_blank: false, **attrs)
          @name = name
          @options = options
          @prompt = prompt
          @required = required
          @disabled = disabled
          @include_blank = include_blank
          super(**attrs)
        end

        attr_reader :name, :options, :prompt, :required, :disabled, :include_blank

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
          classes = "block w-full h-11 rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-gray-900 " \
                    "focus:border-transparent focus:ring-2 focus:ring-primary-500"

          if @disabled
            classes + " border-gray-200 bg-gray-100 text-gray-400 cursor-not-allowed"
          else
            classes
          end
        end

        def render_prompt
          content_tag(:option, @prompt, value: "", disabled: true, selected: @selected.nil?)
        end

        def render_blank
          content_tag(:option, "", value: "")
        end

        def render_options
          safe_join(
            @options.map do |option_data|
              label, value = option_data
              option_attrs = {value: value.to_s}
              option_attrs[:selected] = true if value.to_s == @selected.to_s
              content_tag(:option, label.to_s, **option_attrs)
            end
          )
        end
      end
    end
  end
end
