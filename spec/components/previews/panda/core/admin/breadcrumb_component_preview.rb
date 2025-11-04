# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Breadcrumb Navigation Component
      #
      # A responsive breadcrumb component based on Tailwind UI Plus patterns.
      # Shows a "Back" link on mobile and full breadcrumb trail on larger screens.
      #
      # ## Features
      # - Responsive mobile/desktop layouts
      # - Dark mode support
      # - Accessible navigation with ARIA labels
      # - Chevron separators between items
      #
      # ## Usage
      # ```ruby
      # render Panda::Core::Admin::BreadcrumbComponent.new(
      #   items: [
      #     { text: "Pages", href: "/admin/pages" },
      #     { text: "Blog", href: "/admin/pages/blog" },
      #     { text: "Edit Post", href: "/admin/pages/blog/1/edit" }
      #   ]
      # )
      # ```
      #
      # @label Breadcrumb
      # @display bg_color "#ffffff"
      # @display viewport_width "800px"
      class BreadcrumbComponentPreview < Lookbook::Preview
        # @!group Basic Examples

        # Simple breadcrumb with two items
        # @label Two Items
        def two_items
          render Panda::Core::Admin::BreadcrumbComponent.new(
            items: [
              {text: "Pages", href: "/admin/pages"},
              {text: "Blog Posts", href: "/admin/pages/blog"}
            ]
          )
        end

        # Breadcrumb with three levels
        # @label Three Levels
        def three_levels
          render Panda::Core::Admin::BreadcrumbComponent.new(
            items: [
              {text: "Jobs", href: "/admin/jobs"},
              {text: "Engineering", href: "/admin/jobs/engineering"},
              {text: "Back End Developer", href: "/admin/jobs/engineering/1"}
            ]
          )
        end

        # Breadcrumb with multiple nested levels
        # @label Multiple Levels
        def multiple_levels
          render Panda::Core::Admin::BreadcrumbComponent.new(
            items: [
              {text: "Dashboard", href: "/admin"},
              {text: "Content", href: "/admin/content"},
              {text: "Blog", href: "/admin/content/blog"},
              {text: "2024", href: "/admin/content/blog/2024"},
              {text: "January", href: "/admin/content/blog/2024/01"}
            ]
          )
        end

        # @!endgroup

        # @!group Options

        # Breadcrumb without back link
        # @label Without Back Link
        def without_back
          render Panda::Core::Admin::BreadcrumbComponent.new(
            items: [
              {text: "Dashboard", href: "/admin"}
            ],
            show_back: false
          )
        end

        # @!endgroup

        # @!group Playground

        # Interactive playground to test breadcrumb variations
        #
        # Test different numbers of breadcrumb items and toggle the back link.
        #
        # @label Interactive Playground
        # @param show_back toggle "Show back link on mobile"
        def playground(show_back: true)
          render Panda::Core::Admin::BreadcrumbComponent.new(
            items: [
              {text: "Home", href: "/admin"},
              {text: "Products", href: "/admin/products"},
              {text: "Electronics", href: "/admin/products/electronics"},
              {text: "Laptops", href: "/admin/products/electronics/laptops"}
            ],
            show_back: show_back
          )
        end

        # @!endgroup
      end
    end
  end
end
