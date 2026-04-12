# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TableComponent < Panda::Core::Base
        attr_reader :term, :rows, :icon, :sort, :sort_direction

        def initialize(term: "", rows: [], icon: "", responsive: true, sort: nil, sort_direction: nil, **attrs, &block)
          @term = term
          @rows = rows
          @icon = icon
          @responsive = responsive
          @sort = sort&.to_s
          @sort_direction = (sort_direction&.to_s == "desc") ? "desc" : "asc"
          @columns = []
          @setup_block = block
          super(**attrs)
        end

        def responsive?
          @responsive
        end

        def column(label, width: nil, sortable: false, sort_key: nil, &cell_block)
          @columns << Column.new(label, width, sortable: sortable, sort_key: sort_key, &cell_block)
          self  # Allow chaining
        end

        def render_cell_content(row, cell_block)
          # Use capture to properly handle ERB blocks that output to the template buffer.
          # Directly calling cell_block.call(row) causes double-rendering because ERB blocks
          # both output to the buffer AND return their last expression.
          helpers.capture(row, &cell_block)
        end

        def sort_url_for(column)
          return unless column.sortable?

          new_direction = (sort == column.sort_key && sort_direction == "asc") ? "desc" : "asc"
          request = helpers.request
          query_params = request.query_parameters.merge("sort" => column.sort_key, "direction" => new_direction)
          "#{request.path}?#{query_params.to_query}"
        end

        def sort_indicator_for(column)
          return unless sort == column.sort_key

          (sort_direction == "asc") ? "↑" : "↓"
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
        attr_reader :label, :cell, :width, :sort_key

        def initialize(label, width = nil, sortable: false, sort_key: nil, &block)
          @label = label
          @width = width
          @sortable = sortable
          @sort_key = sort_key || ActiveSupport::Inflector.parameterize(label.to_s, separator: "_")
          @cell = block
        end

        def sortable?
          @sortable
        end
      end
    end
  end
end
