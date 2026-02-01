# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Empty state component for tables and lists.
      class EmptyStateComponent < Panda::Core::Base
        def initialize(title:, description: nil, icon: nil, **attrs)
          @title = title
          @description = description
          @icon = icon
          super(**attrs)
        end

        attr_reader :title, :description, :icon

        def default_attrs
          {
            class: "border-2 border-dashed border-gray-200 bg-white rounded-2xl px-6 py-10 text-center"
          }
        end
      end
    end
  end
end
