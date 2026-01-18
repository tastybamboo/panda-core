# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContainerComponent < Panda::Core::Base
        def initialize(full_height: false, **attrs)
          @full_height = full_height
          super(**attrs)
        end



        def heading(**props, &block)
          @heading_content = -> { render(Panda::Core::Admin::HeadingComponent.new(**props), &block) }
        end

        def tab_bar(**props, &block)
          @tab_bar_content = -> { render(Panda::Core::Admin::TabBarComponent.new(**props), &block) } if defined?(Panda::Core::Admin::TabBarComponent)
        end

        def slideover(**props, &block)
          @slideover_title = props[:title] || "Settings"
          @slideover_block = block
        end

        def footer(&block)
          @footer_block = block
        end

        # Override call to render custom HTML since we have complex DSL logic
        def call
          tag.main(class: "overflow-auto flex-1 h-full min-h-full max-h-full") do
            tag.div(class: "overflow-auto px-2 pt-2 mx-auto sm:px-6 lg:px-6") do
              content_tag(:div) do
                [
                  render_heading,
                  render_tab_bar,
                  render_section
                ].compact.join.html_safe
              end
            end
          end
        end

        private

        attr_reader :full_height

        def section_classes
          base = "flex-auto"
          height = full_height ? "h-[calc(100vh-9rem)]" : nil
          [base, height].compact.join(" ")
        end

        def render_heading
          return unless @heading_content
          @heading_content.call
        end

        def render_tab_bar
          return unless @tab_bar_content
          @tab_bar_content.call
        end

        def render_section
          tag.section(class: section_classes) do
            tag.div(class: "flex-1 mt-4 w-full h-full") do
              # content is a proc - call it to get the rendered HTML
              if content.present?
                content.call
              else
                ""
              end
            end
          end
        end

        # Alias for ViewComponent-style API compatibility
        alias_method :with_slideover, :slideover
        alias_method :with_footer, :footer
      end
    end
  end
end
