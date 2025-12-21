# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class StatisticsComponent < Panda::Core::Base
        prop :metric, String
        prop :value, _Nilable(_Union(String, Integer, Float))

        def view_template
          div(class: "overflow-hidden p-4 bg-gradient-to-br rounded-lg border-2 from-primary-50/20 to-primary-50 border-primary-400") do
            dt(class: "text-base font-medium truncate text-primary-900") { @metric }
            dd(class: "mt-1 text-3xl font-medium tracking-tight text-primary-900") { @value }
          end
        end
      end
    end
  end
end
