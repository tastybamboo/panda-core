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
          @setup_block = block
          super(**attrs)
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

        # Lazy accessor that ensures columns are registered before returning them.
        # Supports two patterns:
        # 1. Block passed to new() - executed here (for tests)
        # 2. Block passed to render() - executed via content (for ERB templates)
        def columns
          unless @columns_registered
            if @setup_block
              # Block was passed to new() - execute it
              @setup_block.call(self)
            else
              # Block was passed to render() - execute via content
              content
            end
            @columns_registered = true
          end
          @columns
        end

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
