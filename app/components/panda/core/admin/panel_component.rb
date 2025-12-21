# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
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

          div(class: "col-span-3 mt-5 rounded-lg shadow-md bg-gray-800 shadow-inherit/20") do
            @heading_content&.call

            div(class: "p-4 text-black bg-white rounded-b-lg") do
              if @body_content
                @body_content.call
              elsif @body_html
                raw(@body_html)
              end
            end
          end
        end

        def heading(**props)
          @heading_content = -> { render(Panda::Core::Admin::HeadingComponent.new(**props.merge(level: :panel))) }
        end

        def body(&block)
          @body_content = block
        end
      end
    end
  end
end
