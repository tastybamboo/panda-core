# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FormErrorComponent < Panda::Core::Base
        prop :errors, _Nilable(_Union(ActiveModel::Errors, Array)), default: -> {}
        prop :model, _Nilable(Object), default: -> {}

        def view_template
          return unless should_render?

          div(**@attrs) do
            div(class: "text-sm text-red-600") do
              error_messages.each do |message|
                p { message }
              end
            end
          end
        end

        def default_attrs
          {
            class: "mb-4 p-4 bg-red-50 border border-red-200 rounded-md"
          }
        end

        private

        def should_render?
          error_messages.any?
        end

        def error_messages
          @error_messages ||= if @model&.respond_to?(:errors)
            @model.errors.full_messages
          elsif @errors.is_a?(ActiveModel::Errors)
            @errors.full_messages
          elsif @errors.is_a?(Array)
            @errors
          else
            []
          end
        end
      end
    end
  end
end
