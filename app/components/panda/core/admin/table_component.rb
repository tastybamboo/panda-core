# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TableComponent < Panda::Core::Base
        attr_reader :term, :rows, :icon

        def initialize(term: "", rows: [], icon: "", **attrs)
          @term = term
          @rows = rows
          @icon = icon
          @columns = []
          super(**attrs)
        end

        def before_render
          # Execute the block to populate columns using the DSL
          instance_eval(&content) if content.present?
        end

        def column(label, width: nil, &cell_block)
          @columns << Column.new(label, width, &cell_block)
          self  # Allow chaining
        end

        def render_cell_content(row, cell_block)
          # Call the block with the row and get the result
          result = cell_block.call(row)

          # Handle different return types
          if result.is_a?(String)
            result
          elsif result.respond_to?(:render_in)
            render(result)
          else
            result.to_s
          end
        end

        private

        attr_reader :columns

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
