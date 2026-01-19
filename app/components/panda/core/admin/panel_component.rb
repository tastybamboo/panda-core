# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
        renders_one :heading, lambda { |**props|
          Panda::Core::Admin::HeadingComponent.new(**props.merge(level: :panel))
        }
        renders_one :body, lambda { |&block|
          ViewComponent::Slot.new(&block)
        }

        def initialize(**attrs)
          super
        end
      end
    end
  end
end
