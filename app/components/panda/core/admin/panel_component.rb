# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
        renders_one :heading_slot, lambda { |**props|
          Panda::Core::Admin::HeadingComponent.new(**props.merge(level: :panel))
        }

        def initialize(**attrs, &block)
          super(**attrs)
          @body_content = nil
          # Execute the block to capture DSL calls
          yield self if block_given?
        end

        def body(&block)
          @body_content = block if block_given?
          @body_content
        end

        def body_slot?
          @body_content.present?
        end

        def body_slot
          @body_content&.call
        end
      end
    end
  end
end
