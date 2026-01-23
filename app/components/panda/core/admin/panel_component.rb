# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
        renders_one :heading_slot, lambda { |**props|
          Panda::Core::Admin::HeadingComponent.new(**props.merge(level: :panel))
        }

        renders_one :body

        def initialize(**attrs)
          super(**attrs)
        end

        # Aliases for backward compatibility
        # Supports: panel.heading(text: "Title") as alias for panel.with_heading_slot(text: "Title")
        def heading(**props)
          with_heading_slot(**props)
        end
      end
    end
  end
end
