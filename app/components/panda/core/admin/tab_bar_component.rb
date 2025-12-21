# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TabBarComponent < Panda::Core::Base
        prop :tabs, Array, default: -> { [].freeze }

        def view_template
          div(class: "mt-3 sm:mt-2") do
            render_mobile_select
            render_desktop_tabs
          end
        end

        private

        def render_mobile_select
          div(class: "sm:hidden") do
            label(for: "tabs", class: "sr-only") { "Select a tab" }
            select(
              id: "tabs",
              name: "tabs",
              class: "block py-1.5 pr-10 pl-3 w-full text-gray-900 rounded-md border-0 ring-1 ring-inset focus:ring-2 focus:ring-inset ring-primary-400 focus:border-primary-600 focus:ring-primary-600"
            ) do
              @tabs.each do |tab|
                option { tab[:name] }
              end
            end
          end
        end

        def render_desktop_tabs
          div(class: "hidden sm:block") do
            div(class: "flex items-center border-b border-gray-200") do
              nav(class: "flex flex-1 -mb-px space-x-6 xl:space-x-8", aria: {label: "Tabs"}) do
                @tabs.each_with_index do |tab, index|
                  render_tab(tab, index.zero?)
                end
              end
              render_view_toggle
            end
          end
        end

        def render_tab(tab, is_current = false)
          classes = "py-4 px-1 text-sm font-medium whitespace-nowrap border-b-2 "
          classes += if is_current || tab[:current]
            "border-primary-600 text-primary-600"
          else
            "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
          end

          a(
            href: tab[:url] || "#",
            class: classes,
            aria: {current: (is_current || tab[:current]) ? "page" : nil}
          ) { tab[:name] }
        end

        def render_view_toggle
          div(class: "hidden items-center p-0.5 ml-6 bg-gray-100 rounded-lg sm:flex") do
            render_view_button(:list)
            render_view_button(:grid, selected: true)
          end
        end

        def render_view_button(type, selected: false)
          button_class = "p-1.5 text-gray-400 rounded-md focus:ring-2 focus:ring-inset focus:outline-none focus:ring-primary-600"
          button_class += if selected
            " ml-0.5 bg-white shadow-sm"
          else
            " hover:bg-white hover:shadow-sm"
          end

          button(type: "button", class: button_class) do
            if type == :list
              svg(class: "w-5 h-5", viewBox: "0 0 20 20", fill: "currentColor", aria: {hidden: "true"}) do |s|
                s.path(
                  fill_rule: "evenodd",
                  d: "M2 3.75A.75.75 0 012.75 3h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 3.75zm0 4.167a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75zm0 4.166a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75zm0 4.167a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75z",
                  clip_rule: "evenodd"
                )
              end
              span(class: "sr-only") { "Use list view" }
            else
              svg(class: "w-5 h-5", viewBox: "0 0 20 20", fill: "currentColor", aria: {hidden: "true"}) do |s|
                s.path(
                  fill_rule: "evenodd",
                  d: "M4.25 2A2.25 2.25 0 002 4.25v2.5A2.25 2.25 0 004.25 9h2.5A2.25 2.25 0 009 6.75v-2.5A2.25 2.25 0 006.75 2h-2.5zm0 9A2.25 2.25 0 002 13.25v2.5A2.25 2.25 0 004.25 18h2.5A2.25 2.25 0 009 15.75v-2.5A2.25 2.25 0 006.75 11h-2.5zm9-9A2.25 2.25 0 0011 4.25v2.5A2.25 2.25 0 0013.25 9h2.5A2.25 2.25 0 0018 6.75v-2.5A2.25 2.25 0 0015.75 2h-2.5zm0 9A2.25 2.25 0 0011 13.25v2.5A2.25 2.25 0 0013.25 18h2.5A2.25 2.25 0 0018 15.75v-2.5A2.25 2.25 0 0015.75 11h-2.5z",
                  clip_rule: "evenodd"
                )
              end
              span(class: "sr-only") { "Use grid view" }
            end
          end
        end
      end
    end
  end
end
