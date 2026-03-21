# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Renders a right-aligned delete button using `button_to` with DELETE method
      # and a Turbo confirmation dialog.
      #
      # Lives in panda-core because every admin app needs destructive action buttons,
      # and the existing ButtonComponent renders `<a>` tags rather than `<form>`-based
      # `button_to` elements required for safe DELETE requests (CSRF + method override).
      #
      # @example Basic usage
      #   render Panda::Core::Admin::DeleteButtonComponent.new(
      #     text: "Delete Person",
      #     path: person_path(@person),
      #     confirm: "Are you sure you want to delete this person?"
      #   )
      class DeleteButtonComponent < Panda::Core::Base
        attr_reader :text, :path, :confirm

        def initialize(text:, path:, confirm:, **attrs)
          @text = text
          @path = path
          @confirm = confirm
          super(**attrs)
        end

        private

        def default_attrs
          {
            class: "inline-flex items-center gap-2 rounded-xl px-3 py-1.5 text-sm font-medium " \
                   "text-error-600 border border-error-200 bg-error-50 hover:bg-error-100 " \
                   "shadow-sm cursor-pointer transition-colors"
          }
        end
      end
    end
  end
end
