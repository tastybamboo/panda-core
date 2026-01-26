# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PanelComponent < Panda::Core::Base
        renders_one :heading_slot

        renders_one :body_slot

        def initialize(**attrs)
          super(**attrs)
        end
      end
    end
  end
end
