# frozen_string_literal: true

module Panda
  module Core
    module UI
      # Card component for containing related content.
      #
      # Cards are flexible containers that can hold any content,
      # with optional padding, shadows, and border variations.
      #
      # @example Basic card
      #   render Panda::Core::UI::Card.new do
      #     "Card content here"
      #   end
      #
      # @example Card with header and footer
      #   render Panda::Core::UI::Card.new(padding: :large) do |card|
      #     card.with_header { h3 { "Card Title" } }
      #     card.with_body { p { "Main content" } }
      #     card.with_footer { "Footer content" }
      #   end
      #
      # @example Elevated card with no padding
      #   render Panda::Core::UI::Card.new(
      #     elevation: :high,
      #     padding: :none
      #   ) do
      #     img(src: "/image.jpg", alt: "Card image")
      #   end
      #
      class Card < Panda::Core::Base
    def initialize(padding: :medium, elevation: :low, border: true, **attrs)
    @padding = padding
    @elevation = elevation
    @border = border
      super(**attrs)
    end

    attr_reader :padding, :elevation, :border

        def default_attrs
          {
            class: card_classes
          }
        end

        private

        def card_classes
          base = "bg-white rounded-lg overflow-hidden"
          base += " #{padding_classes}"
          base += " #{elevation_classes}"
          base += " #{border_classes}"
          base
        end

        def padding_classes
          case padding
          when :none
            ""
          when :small, :sm
            "p-4"
          when :large, :lg
            "p-8"
          else # :medium, :md
            "p-6"
          end
        end

        def elevation_classes
          case elevation
          when :none
            ""
          when :medium, :md
            "shadow-md"
          when :high, :lg
            "shadow-lg"
          else # :low, :sm
            "shadow-sm"
          end
        end

        def border_classes
          border ? "border border-gray-200" : ""
        end
      end
    end
  end
end
