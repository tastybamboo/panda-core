# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TabBarComponent < Panda::Core::Base
        def initialize(tabs: [].freeze, **attrs)
          @tabs = tabs
          super(**attrs)
        end

        attr_reader :tabs

        private

        def any_tab_current?
          @any_tab_current ||= @tabs.any? { |tab| tab[:current] }
        end

        def tab_current?(tab, index)
          tab[:current] || (!any_tab_current? && index.zero?)
        end

        def tab_classes(tab, index)
          classes = "py-4 px-1 text-sm font-medium whitespace-nowrap border-b-2 "
          classes += if tab_current?(tab, index)
            "border-primary-600 text-primary-600"
          else
            "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
          end
          classes
        end

        def view_button_classes(selected)
          button_class = "p-1.5 text-gray-400 rounded-md focus:ring-2 focus:ring-inset focus:outline-none focus:ring-primary-600"
          button_class += if selected
            " ml-0.5 bg-white shadow-sm"
          else
            " hover:bg-white hover:shadow-sm"
          end
          button_class
        end

        def list_view_icon
          content_tag(:svg, class: "w-5 h-5", viewBox: "0 0 20 20", fill: "currentColor", aria: {hidden: "true"}) do
            tag.path(
              fill_rule: "evenodd",
              d: "M2 3.75A.75.75 0 012.75 3h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 3.75zm0 4.167a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75zm0 4.166a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75zm0 4.167a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75z",
              clip_rule: "evenodd"
            )
          end
        end

        def grid_view_icon
          content_tag(:svg, class: "w-5 h-5", viewBox: "0 0 20 20", fill: "currentColor", aria: {hidden: "true"}) do
            tag.path(
              fill_rule: "evenodd",
              d: "M4.25 2A2.25 2.25 0 002 4.25v2.5A2.25 2.25 0 004.25 9h2.5A2.25 2.25 0 009 6.75v-2.5A2.25 2.25 0 006.75 2h-2.5zm0 9A2.25 2.25 0 002 13.25v2.5A2.25 2.25 0 004.25 18h2.5A2.25 2.25 0 009 15.75v-2.5A2.25 2.25 0 006.75 11h-2.5zm9-9A2.25 2.25 0 0011 4.25v2.5A2.25 2.25 0 0013.25 9h2.5A2.25 2.25 0 0018 6.75v-2.5A2.25 2.25 0 0015.75 2h-2.5zm0 9A2.25 2.25 0 0011 13.25v2.5A2.25 2.25 0 0013.25 18h2.5A2.25 2.25 0 0018 15.75v-2.5A2.25 2.25 0 0015.75 11h-2.5z",
              clip_rule: "evenodd"
            )
          end
        end
      end
    end
  end
end
