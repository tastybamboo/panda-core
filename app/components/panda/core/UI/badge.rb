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
        def initialize(text:, variant: :default, size: :medium, removable: false, rounded: false, **attrs)
          @text = text
          @variant = variant
          @size = size
          @removable = removable
          @rounded = rounded
          super(**attrs)
        end

        attr_reader :text, :variant, :size, :removable, :rounded

        def removable?
          removable
        end

        private

        def default_attrs
          {
            class: badge_classes
          }
        end

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
