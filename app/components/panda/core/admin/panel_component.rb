# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
        def initialize(**attrs)
          super(**attrs)
        end

        def before_render
          # Capture block content if provided
          instance_eval(&content) if content.present?
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
