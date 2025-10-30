# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class StatisticsComponent < Panda::Core::Base
        prop :metric, String
        prop :value, _Nilable(_Union(String, Integer, Float))

        def view_template
          div(class: "overflow-hidden p-4 bg-gradient-to-br rounded-lg border-2 from-light/20 to-light border-mid") do
            dt(class: "text-base font-medium truncate text-dark") { @metric }
            dd(class: "mt-1 text-3xl font-medium tracking-tight text-dark") { @value }
          end
        end
      end
    end
  end
end
