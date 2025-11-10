# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContainerComponent < Panda::Core::Base
        prop :full_height, _Nilable(_Boolean), default: -> { false }

        def view_template(&block)
          # Capture block content differently based on context (ERB vs Phlex)
          if block_given?
            if defined?(view_context) && view_context
              # Called from ERB - capture HTML output
              @body_html = view_context.capture { yield(self) }
            else
              # Called from Phlex - execute block directly to set instance variables
              yield(self)
            end
          end

          # Set content_for :sidebar if slideover is present (enables breadcrumb toggle button)
          # This must happen before rendering so the layout can use it
          if @slideover_block && @slideover_title && defined?(view_context) && view_context
            view_context.content_for(:sidebar) do
              # The block contains ERB content, capture it for the sidebar
              view_context.capture(&@slideover_block)
            end
            view_context.content_for(:sidebar_title, @slideover_title)

            # Set footer content if present
            if @footer_block
              view_context.content_for(:sidebar_footer) do
                view_context.capture(&@footer_block)
              end
            end
          end

          main(class: "overflow-auto flex-1 h-full min-h-full max-h-full") do
            div(class: "overflow-auto px-2 pt-2 mx-auto sm:px-6 lg:px-6") do
              @heading_content&.call
              @tab_bar_content&.call

              section(class: section_classes) do
                div(class: "flex-1 mt-4 w-full h-full") do
                  if @main_content
                    @main_content.call
                  elsif @body_html
                    raw(@body_html)
                  end
                end
              end
            end
          end
        end

        def content(&block)
          @main_content = if defined?(view_context) && view_context
            # Capture ERB content
            -> { raw(view_context.capture(&block)) }
          else
            block
          end
        end

        def heading(**props, &block)
          @heading_content = -> { render(Panda::Core::Admin::HeadingComponent.new(**props), &block) }
        end

        def tab_bar(**props, &block)
          @tab_bar_content = -> { render(Panda::Core::Admin::TabBarComponent.new(**props), &block) } if defined?(Panda::Core::Admin::TabBarComponent)
        end

        def slideover(**props, &block)
          @slideover_title = props[:title] || "Settings"
          @slideover_block = block   # Save the block for content_for
        end

        def footer(&block)
          @footer_block = block
        end

        # Alias for ViewComponent-style API compatibility
        alias_method :with_slideover, :slideover
        alias_method :with_footer, :footer

        private

        def section_classes
          base = "flex-auto"
          height = @full_height ? "h-[calc(100vh-9rem)]" : nil
          [base, height].compact.join(" ")
        end
      end
    end
  end
end
