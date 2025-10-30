# frozen_string_literal: true

module Panda
  module Core
    module UI
      # Badge component for status indicators, labels, and counts.
      #
      # Badges are small, inline elements that highlight an item's status
      # or provide additional metadata at a glance.
      #
      # @example Basic badge
      #   render Panda::Core::UI::Badge.new(text: "New")
      #
      # @example Status badges
      #   render Panda::Core::UI::Badge.new(text: "Active", variant: :success)
      #   render Panda::Core::UI::Badge.new(text: "Pending", variant: :warning)
      #   render Panda::Core::UI::Badge.new(text: "Error", variant: :danger)
      #
      # @example With count
      #   render Panda::Core::UI::Badge.new(text: "99+", variant: :primary, size: :small)
      #
      # @example Removable badge
      #   render Panda::Core::UI::Badge.new(
      #     text: "Tag",
      #     removable: true,
      #     data: { action: "click->tags#remove" }
      #   )
      #
      class Badge < Panda::Core::Base
        prop :text, String
        prop :variant, Symbol, default: :default
        prop :size, Symbol, default: :medium
        prop :removable, _Boolean, default: false
        prop :rounded, _Boolean, default: false

        def view_template
          span(**@attrs) do
            plain text
            if removable
              whitespace
              button(
                type: "button",
                class: "inline-flex items-center ml-1 hover:opacity-70",
                aria: {label: "Remove"}
              ) do
                svg(
                  class: "h-3 w-3",
                  xmlns: "http://www.w3.org/2000/svg",
                  viewBox: "0 0 20 20",
                  fill: "currentColor"
                ) do |s|
                  s.path(
                    d: "M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
                  )
                end
              end
            end
          end
        end

        def default_attrs
          {
            class: badge_classes
          }
        end

        private

        def badge_classes
          base = "inline-flex items-center font-medium"
          base += " #{size_classes}"
          base += " #{variant_classes}"
          base += rounded ? " rounded-full" : " rounded"
          base
        end

        def size_classes
          case size
          when :small, :sm
            "px-2 py-0.5 text-xs"
          when :large, :lg
            "px-3 py-1 text-base"
          else # :medium, :md
            "px-2.5 py-0.5 text-sm"
          end
        end

        def variant_classes
          case variant
          when :primary
            "bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-700/10"
          when :success
            "bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20"
          when :warning
            "bg-yellow-50 text-yellow-800 ring-1 ring-inset ring-yellow-600/20"
          when :danger
            "bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/10"
          when :info
            "bg-sky-50 text-sky-700 ring-1 ring-inset ring-sky-700/10"
          else # :default
            "bg-gray-50 text-gray-600 ring-1 ring-inset ring-gray-500/10"
          end
        end
      end
    end
  end
end
