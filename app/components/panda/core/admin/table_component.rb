# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TableComponent < Panda::Core::Base
        def initialize(term: "", rows: [], icon: "", **attrs)
          @term = term
          @rows = rows
          @icon = icon
          @columns = []
          super(**attrs)
        end

        attr_reader :term, :rows, :icon, :columns

        def before_render
          # Capture the block to populate columns
          instance_eval(&content) if content.present?
        end

        def column(label, width: nil, &cell_block)
          @columns << Column.new(label, width, &cell_block)
        end

        private

        def render_cell_content(row, cell_block)
          # When called from ERB, we need to capture the block's output buffer
          # When called from Phlex, evaluate directly
          if defined?(view_context) && view_context
            # Use capture to get ERB output buffer content
            captured_html = view_context.capture(row, &cell_block)
            # Render the captured HTML (already html_safe from capture)
            raw(captured_html)
          else
            # Pure Phlex context - execute block directly
            result = cell_block.call(row)

            # Handle different return types
            if result.is_a?(String)
              plain(result)
            elsif result.respond_to?(:render_in)
              render(result)
            else
              plain(result.to_s)
            end
          end
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
