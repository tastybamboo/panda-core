# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
        renders_one :heading_slot, lambda { |**props, &block|
          Panda::Core::Admin::HeadingComponent.new(**props.merge(level: :panel), &block)
        }

        renders_one :body_slot

        def initialize(**attrs)
          super(**attrs)
        end
      end
    end
  end
end
