# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FormSelectComponent < Panda::Core::Base
    def initialize(name: "", options: [], prompt:, required: false, disabled: false, include_blank: false, **attrs)
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
          classes = "block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset focus:ring-2 focus:ring-inset sm:leading-6"

          if @disabled
            classes + " ring-gray-300 focus:ring-gray-300 bg-gray-50 cursor-not-allowed"
          else
            classes + " ring-primary-400 focus:ring-primary-600 hover:cursor-pointer"
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
