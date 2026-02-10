# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FilterPillsComponent < Panda::Core::Base
        def initialize(items:, url_helper:, param_name: :category, active_value: nil, all_label: "All", **attrs)
          @items = items
          @url_helper = url_helper
          @param_name = param_name
          @active_value = active_value
          @all_label = all_label
          super(**attrs)
        end

        attr_reader :items, :url_helper, :param_name, :active_value, :all_label

        def pill_classes(active)
          base = "inline-flex items-center rounded-full px-3 py-1.5 text-xs font-medium"
          if active
            "#{base} bg-primary-100 text-primary-700"
          else
            "#{base} bg-gray-100 text-gray-700 hover:bg-gray-200"
          end
        end
      end
    end
  end
end
