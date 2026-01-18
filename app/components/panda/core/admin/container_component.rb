# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContainerComponent < Panda::Core::Base
    def initialize(full_height: false, **attrs)
    @full_height = full_height
      super(**attrs)
    end

    attr_reader :full_height

        def before_render
           # Capture block content differently based on context (ERB vs Phlex)
           # The block yields self to allow DSL-style calls like container.heading(...)
           if content.present?
             if defined?(view_context) && view_context
               # Called from ERB - capture the block content
               # Don't pass self as an argument - just call the block
               @body_html = view_context.capture(&content)
             else
               # Called from Phlex - execute block directly to set instance variables
               content.call(self)
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

         def render_body_content
           @body_html || content
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
