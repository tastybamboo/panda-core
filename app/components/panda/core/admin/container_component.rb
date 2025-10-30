# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContainerComponent < Panda::Core::Base
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

          main(class: "overflow-auto flex-1 h-full min-h-full max-h-full") do
            div(class: "overflow-auto px-2 pt-4 mx-auto sm:px-6 lg:px-6") do
              @heading_content&.call
              @tab_bar_content&.call

              section(class: "flex-auto") do
                div(class: "flex-1 mt-4 w-full") do
                  if @main_content
                    @main_content.call
                  elsif @body_html
                    raw(@body_html)
                  end
                end
                @slideover_content&.call
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
          @slideover_content = -> { render(Panda::Core::Admin::SlideoverComponent.new(**props), &block) }
        end
      end
    end
  end
end
