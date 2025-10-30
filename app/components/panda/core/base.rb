# frozen_string_literal: true

module Panda
  module Core
    # Base class for all Phlex components in the Panda ecosystem.
    #
    # This base component provides:
    # - Type-safe properties via Literal
    # - Tailwind CSS class merging
    # - Attribute merging with sensible defaults
    # - Rails helper integration
    # - Development-mode debugging comments
    #
    # @example Basic usage
    #   class MyComponent < Panda::Core::Base
    #     prop :title, String
    #     prop :variant, Symbol, default: :primary
    #
    #     def view_template
    #       div(**@attrs) { title }
    #     end
    #
    #     def default_attrs
    #       { class: "my-component my-component--#{variant}" }
    #     end
    #   end
    #
    # @example With attribute merging
    #   # Component definition
    #   class Button < Panda::Core::Base
    #     prop :text, String
    #
    #     def view_template
    #       button(**@attrs) { text }
    #     end
    #
    #     def default_attrs
    #       { class: "btn btn-primary", type: "button" }
    #     end
    #   end
    #
    #   # Usage - user attrs merge with defaults
    #   render Button.new(text: "Click me", class: "mt-4", type: "submit")
    #   # => <button type="submit" class="btn btn-primary mt-4">Click me</button>
    #
    class Base < Phlex::HTML
      # Frozen instance of TailwindMerge for efficient class merging
      TAILWIND_MERGER = ::TailwindMerge::Merger.new.freeze unless defined?(TAILWIND_MERGER)

      # Enable type-safe properties via Literal
      extend Literal::Properties

      # Include Rails helpers for routes, etc.
      include Phlex::Rails::Helpers::Routes

      # Special handling for the attrs property - merges user attributes with defaults
      # and intelligently handles Tailwind class merging
      #
      # @param value [Hash] User-provided attributes
      # @return [Hash] Merged attributes with Tailwind classes properly combined
      prop :attrs, Hash, :**, reader: :private do |value|
        merge_attrs(value, default_attrs)
      end

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

      # In development mode, wrap components with HTML comments
      # showing their class name for easier debugging
      if Rails.env.development?
        def before_template
          class_name = self.class.name
          comment { "Begin #{class_name}" }
          super
        end

        def after_template
          class_name = self.class.name
          super
          comment { "End #{class_name}" }
        end
      end
    end
  end
end
