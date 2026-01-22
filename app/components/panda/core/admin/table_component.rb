# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TableComponent < Panda::Core::Base
        attr_reader :term, :rows, :icon

        def initialize(term: "", rows: [], icon: "", **attrs, &block)
          @term = term
          @rows = rows
          @icon = icon
          @columns = []
          super(**attrs)
          # Execute the block if provided to populate columns
          yield self if block_given?
        end

        def column(label, width: nil, &cell_block)
          @columns << Column.new(label, width, &cell_block)
          self  # Allow chaining
        end

        def render_cell_content(row, cell_block)
          # Use capture to properly handle ERB blocks that output to the template buffer.
          # Directly calling cell_block.call(row) causes double-rendering because ERB blocks
          # both output to the buffer AND return their last expression.
          helpers.capture(row, &cell_block)
        end

        attr_reader :columns

        private

        def pluralized_term
          @pluralized_term ||= ActiveSupport::Inflector.pluralize(term)
        end
      end

      class Column
        attr_reader :label, :cell, :width

        def initialize(label, width = nil, &block)
          @label = label
          @width = width
          @cell = block
        end
      end
    end
  end
end
