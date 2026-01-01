# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TableComponent < Panda::Core::Base
        prop :term, String
        prop :rows, _Nilable(Object), default: -> { [] }
        prop :icon, String, default: ""

        attr_reader :columns

        def initialize(**props)
          super
          @columns = []
        end

        def view_template(&block)
          # Capture the block to populate columns
          instance_eval(&block) if block_given?

          if @rows.any?
            render_table_with_rows
          else
            render_empty_table
          end
        end

        def column(label, width: nil, &cell_block)
          @columns << Column.new(label, width, &cell_block)
        end

        private

        def render_table_with_rows
          div(class: "table overflow-x-auto mb-12 w-full rounded-lg border border-gray-700", style: "table-layout: fixed;") do
            render_header
            render_rows
          end
        end

        def render_empty_table
          div(class: "text-center block border border-dashed py-12 rounded-lg") do
            i(class: "#{@icon} text-4xl text-gray-400 mb-3") if @icon.present?
            h3(class: "py-1 text-xl font-semibold text-gray-900") { "No #{@term.pluralize}" }
            p(class: "py-1 text-base text-gray-500") { "Get started by creating a new #{@term}." }
          end
        end

        def render_header
          div(class: "table-header-group") do
            div(class: "table-row text-base font-medium text-white bg-gray-800") do
              @columns.each_with_index do |column, i|
                header_classes = "table-cell sticky top-0 z-10 p-4"
                header_classes += " rounded-tl-md" if i.zero?
                header_classes += " rounded-tr-md" if i == @columns.size - 1

                header_style = column.width ? "width: #{column.width};" : nil
                div(class: header_classes, style: header_style) { column.label }
              end
            end
          end
        end

        def render_rows
          div(class: "table-row-group") do
            @rows.each do |row|
              div(
                class: "table-row relative bg-gray-500/5 hover:bg-gray-500/20",
                data: {post_id: row.id}
              ) do
                @columns.each do |column|
                  div(class: "table-cell py-5 px-3 h-20 text-sm align-middle whitespace-nowrap border-b border-gray-700/20") do
                    # Capture the cell content by calling the block with the row
                    render_cell_content(row, column.cell)
                  end
                end
              end
            end
          end
        end

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
