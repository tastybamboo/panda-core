# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TableComponent < ViewComponent::Base
        attr_reader :columns

        def initialize(term:, rows:)
          @term = term
          @rows = rows
          @columns = []
        end

        def column(label, &)
          @columns << Column.new(label, &)
        end

        private

        # Ensures @columns gets populated [https://dev.to/rolandstuder/supercharged-table-component-built-with-viewcomponent-3j6i]
        def before_render
          content
        end
      end

      class Column
        attr_reader :label, :cell

        def initialize(label, &block)
          @label = label
          @cell = block
        end
      end

      class TagColumn < Column
        attr_reader :label, :cell

        def initialize(label, &block)
          @label = label
          @cell = Panda::Core::Admin::TagComponent.new(status: block)
        end
      end
    end
  end
end
