# frozen_string_literal: true

module Panda
  module Core
    module UI
      # Card Component for Content Containers
      #
      # Cards are versatile containers for grouping related content.
      # They provide visual separation and hierarchy through elevation,
      # padding, and borders.
      #
      # ## Design Principles
      # - Use cards to group related information
      # - Maintain consistent spacing and elevation
      # - Don't nest cards too deeply (max 2 levels)
      # - Consider mobile viewports when sizing
      #
      # ## Performance
      # - Lightweight - no JavaScript required
      # - Leverages Tailwind for optimal CSS
      # - Renders efficiently with Phlex
      #
      # @label Card (ViewComponent)
      # @display bg_color "#f3f4f6"
      class CardPreview < Lookbook::Preview
        # @!group Basic Cards

        # Simple card with default settings
        # @label Default Card
        def default
          render Panda::Core::UI::Card.new do |card|
            card.p(class: "text-gray-700") { "This is a simple card with default padding and elevation." }
          end
        end

        # @!endgroup

        # @!group Padding Variations

        # Card with no padding
        #
        # Useful for images or content that should touch the edges
        # @label No Padding
        def no_padding
          render Panda::Core::UI::Card.new(padding: :none) do |card|
            card.div(class: "bg-gradient-to-r from-blue-500 to-purple-600 h-32 flex items-center justify-center") do
              card.span(class: "text-white font-semibold") { "Full Bleed Content" }
            end
          end
        end

        # Small padding for compact cards
        # @label Small Padding
        def small_padding
          render Panda::Core::UI::Card.new(padding: :small) do |card|
            card.p(class: "text-sm text-gray-700") { "Compact card with small padding" }
          end
        end

        # Medium padding (default)
        # @label Medium Padding
        def medium_padding
          render Panda::Core::UI::Card.new(padding: :medium) do |card|
            card.p(class: "text-gray-700") { "Standard card with medium padding" }
          end
        end

        # Large padding for spacious layouts
        # @label Large Padding
        def large_padding
          render Panda::Core::UI::Card.new(padding: :large) do |card|
            card.p(class: "text-gray-700") { "Spacious card with large padding" }
          end
        end

        # @!endgroup

        # @!group Elevation Levels

        # Flat card with no shadow
        # @label No Elevation
        def no_elevation
          render Panda::Core::UI::Card.new(elevation: :none) do |card|
            card.p(class: "text-gray-700") { "Flat card with no shadow" }
          end
        end

        # Subtle shadow (default)
        # @label Low Elevation
        def low_elevation
          render Panda::Core::UI::Card.new(elevation: :low) do |card|
            card.p(class: "text-gray-700") { "Card with subtle shadow" }
          end
        end

        # Medium shadow for more emphasis
        # @label Medium Elevation
        def medium_elevation
          render Panda::Core::UI::Card.new(elevation: :medium) do |card|
            card.p(class: "text-gray-700") { "Card with medium shadow" }
          end
        end

        # Strong shadow for maximum emphasis
        # @label High Elevation
        def high_elevation
          render Panda::Core::UI::Card.new(elevation: :high) do |card|
            card.p(class: "text-gray-700") { "Card with strong shadow" }
          end
        end

        # @!endgroup

        # @!group Border Options

        # Card without border
        # @label No Border
        def no_border
          render Panda::Core::UI::Card.new(border: false) do |card|
            card.p(class: "text-gray-700") { "Card without border" }
          end
        end

        # Card with border (default)
        # @label With Border
        def with_border
          render Panda::Core::UI::Card.new(border: true) do |card|
            card.p(class: "text-gray-700") { "Card with border" }
          end
        end

        # @!endgroup

        # @!group Playground

        # Interactive playground for testing card variations
        #
        # Experiment with different combinations to find the perfect
        # card style for your use case.
        #
        # @label Playground
        # @param padding select { choices: [none, small, medium, large] }
        # @param elevation select { choices: [none, low, medium, high] }
        # @param border toggle "Show border"
        def playground(
          padding: "medium",
          elevation: "low",
          border: true
        )
          render Panda::Core::UI::Card.new(
            padding: padding.to_sym,
            elevation: elevation.to_sym,
            border: border
          ) do |card|
            card.h3(class: "text-lg font-semibold text-gray-900 mb-2") { "Card Title" }
            card.p(class: "text-gray-600") do
              "This is a card with customizable padding, elevation, and border settings."
            end
          end
        end

        # @!endgroup
      end
    end
  end
end
