# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
        renders_one :heading_slot, lambda { |**props, &block|
          Panda::Core::Admin::HeadingComponent.new(**props.merge(level: :panel), &block)
        }

        renders_one :body

        def initialize(**attrs)
          super(**attrs)
        end

        # Aliases for backward compatibility
        # Supports: panel.heading(text: "Title") as alias for panel.with_heading_slot(text: "Title")
        def heading(**props, &block)
          with_heading_slot(**props, &block)
        end
      end
    end
  end
end
