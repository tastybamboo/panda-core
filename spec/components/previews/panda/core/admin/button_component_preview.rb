# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Button
      class ButtonComponentPreview < ViewComponent::Preview
        # Default button with no specific action
        # @label Default
        def default
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Click me",
            link: "#"
          )
        end

        # Primary save/create action button with green styling
        # @label Save Action
        def save_action
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Save changes",
            action: :save,
            link: "#"
          )
        end

        # Create/add action button
        # @label Create Action
        def create_action
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Create new",
            action: :create,
            link: "#"
          )
        end

        # Secondary neutral action button
        # @label Secondary Action
        def secondary_action
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Cancel",
            action: :secondary,
            link: "#"
          )
        end

        # Destructive delete action with red styling
        # @label Delete Action
        def delete_action
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Delete item",
            action: :delete,
            link: "#"
          )
        end

        # Inactive save button (disabled state)
        # @label Inactive Save
        def inactive_save
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Save",
            action: :save_inactive,
            link: "#"
          )
        end

        # Small button size
        # @label Small Size
        def small_size
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Small button",
            size: :small,
            link: "#"
          )
        end

        # Medium/regular button size (default)
        # @label Medium Size
        def medium_size
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Medium button",
            size: :medium,
            link: "#"
          )
        end

        # Large button size
        # @label Large Size
        def large_size
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Large button",
            size: :large,
            link: "#"
          )
        end

        # Button with custom icon
        # @label With Icon
        def with_icon
          render Panda::Core::Admin::ButtonComponent.new(
            text: "Settings",
            icon: "gear",
            link: "#"
          )
        end

        # Complete comparison of all button sizes
        # @label Size Comparison
        def size_comparison
          render_inline Panda::Core::Admin::ButtonComponent.new(
            text: "Small",
            size: :small,
            action: :save,
            link: "#"
          )
          render_inline "  "
          render_inline Panda::Core::Admin::ButtonComponent.new(
            text: "Medium",
            size: :medium,
            action: :save,
            link: "#"
          )
          render_inline "  "
          render_inline Panda::Core::Admin::ButtonComponent.new(
            text: "Large",
            size: :large,
            action: :save,
            link: "#"
          )
        end

        # Interactive playground with dynamic parameters
        # @label Playground
        # @param text text "Button text"
        # @param action select { choices: [default, save, create, secondary, delete, danger] }
        # @param size select { choices: [small, medium, large] }
        # @param icon text "FontAwesome icon name (optional)"
        def playground(text: "Button", action: "default", size: "medium", icon: nil)
          render Panda::Core::Admin::ButtonComponent.new(
            text: text,
            action: action.to_sym,
            size: size.to_sym,
            icon: icon.presence,
            link: "#"
          )
        end
      end
    end
  end
end
