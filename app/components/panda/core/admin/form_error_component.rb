# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FormErrorComponent < Panda::Core::Base
    def initialize(model:, **attrs)
    @model = model
      super(**attrs)
    end

    attr_reader :model


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
