# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SearchFilterBarComponent < Panda::Core::Base
        renders_many :filters

        def initialize(url:, search_name: :q, search_value: nil, search_placeholder: "Search...", clear_url: nil, show_clear: false, **attrs)
          @url = url
          @search_name = search_name
          @search_value = search_value
          @search_placeholder = search_placeholder
          @clear_url = clear_url || url
          @show_clear = show_clear
          super(**attrs)
        end

        attr_reader :url, :search_name, :search_value, :search_placeholder, :clear_url, :show_clear

        def select_classes
          "w-auto rounded-md border-0 py-2 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-primary-600 sm:text-sm dark:bg-gray-700 dark:text-white dark:ring-gray-600"
        end
      end
    end
  end
end
