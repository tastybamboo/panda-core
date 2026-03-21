# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Renders a PanelComponent containing prose-formatted text via `simple_format`.
      # Self-hides via `render?` when text is blank.
      #
      # Lives in panda-core because rich-text prose display inside panels is a generic
      # admin pattern (notes, descriptions, agendas) used across any Panda app, not
      # specific to any single domain.
      #
      # @example Basic usage
      #   render Panda::Core::Admin::ProsePanelComponent.new(heading: "Notes", text: @person.notes)
      #
      # @example With extra prose styling
      #   render Panda::Core::Admin::ProsePanelComponent.new(
      #     heading: "Internal Notes",
      #     text: @case.notes,
      #     prose_class: "text-gray-600"
      #   )
      class ProsePanelComponent < Panda::Core::Base
        attr_reader :heading, :text, :prose_class

        def initialize(heading:, text:, prose_class: "", **attrs)
          @heading = heading
          @text = text
          @prose_class = prose_class
          super(**attrs)
        end

        def render?
          text.present?
        end

        def prose_classes
          base = "prose prose-sm max-w-none"
          prose_class.present? ? "#{base} #{prose_class}" : base
        end
      end
    end
  end
end
