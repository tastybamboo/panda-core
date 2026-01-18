# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class StatisticsComponent < Panda::Core::Base
        def initialize(metric: "", value: nil, **attrs)
          @metric = metric
          @value = value
          super(**attrs)
        end

        attr_reader :metric, :value
      end
    end
  end
end
