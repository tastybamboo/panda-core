# frozen_string_literal: true

module Panda
  module Core
    # Base class for all ViewComponent components in the Panda ecosystem.
    #
    # This base component provides:
    # - Tailwind CSS class merging via TailwindMerge
    # - Attribute merging with sensible defaults
    # - Rails helper integration (inherited from ViewComponent::Base)
    # - Development-mode debugging comments
    #
    # @example Basic usage
    #   class MyComponent < Panda::Core::Base
    #     def initialize(title:, variant: :primary, **attrs)
    #       @title = title
    #       @variant = variant
    #       super(**attrs)
    #     end
    #
    #     attr_reader :title, :variant
    #
    #     private
    #
    #     def default_attrs
    #       { class: "my-component my-component--#{variant}" }
    #     end
    #   end
    #
    # @example With attribute merging
    #   # Component definition
    #   class ButtonComponent < Panda::Core::Base
    #     def initialize(text:, **attrs)
    #       @text = text
    #       super(**attrs)
    #     end
    #
    #     attr_reader :text
    #
    #     private
    #
    #     def default_attrs
    #       { class: "btn btn-primary", type: "button" }
    #     end
    #   end
    #
    #   # Usage - user attrs merge with defaults
    #   render ButtonComponent.new(text: "Click me", class: "mt-4", type: "submit")
    #   # => <button type="submit" class="btn btn-primary mt-4">Click me</button>
    #
    class Base < ViewComponent::Base
      # Frozen instance of TailwindMerge for efficient class merging
      TAILWIND_MERGER = ::TailwindMerge::Merger.new.freeze unless defined?(TAILWIND_MERGER)

      # Initialize the component with user-provided attributes.
      # Subclasses should call super(**attrs) after setting their own instance variables.
      #
      # @param attrs [Hash] User-provided HTML attributes
      def initialize(**user_attrs)
        super()
        @attrs = merge_attrs(user_attrs, default_attrs)
      end

      private

      attr_reader :attrs

      # Merges user-provided attributes with default attributes.
      # Special handling for :class to merge Tailwind classes intelligently.
      #
      # @param user_attrs [Hash] Attributes provided by the user
      # @param default_attrs [Hash] Default attributes from the component
      # @return [Hash] Merged attributes
      def merge_attrs(user_attrs, default_attrs)
        attrs = default_attrs.merge(user_attrs)
        if attrs[:class].is_a?(String)
          attrs[:class] = TAILWIND_MERGER.merge(attrs[:class])
        end
        attrs
      end

      # Helper alias for merge_attrs with clearer intent
      #
      # @param user_attrs [Hash] Attributes provided by the user
      # @param default_attrs [Hash] Default attributes from the component
      # @return [Hash] Merged attributes with Tailwind classes combined
      def tailwind_merge_attrs(user_attrs, default_attrs)
        merge_attrs(user_attrs, default_attrs)
      end

      # Override this method in subclasses to provide default attributes
      # for your component.
      #
      # @return [Hash] Default HTML attributes for the component
      #
      # @example
      #   def default_attrs
      #     {
      #       class: "btn btn-#{variant}",
      #       type: "button",
      #       data: { controller: "button" }
      #     }
      #   end
      def default_attrs
        {}
      end

      # ViewComponent automatically renders templates in the same directory
      # We override call to make it public for testing
      def call
        super
      end
    end
  end
end
