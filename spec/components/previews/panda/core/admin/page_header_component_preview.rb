# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Page Header Component with Actions
      #
      # A comprehensive page header component based on Tailwind UI Plus patterns.
      # Combines title, breadcrumbs, and action buttons in a responsive layout.
      #
      # ## Features
      # - Optional breadcrumb navigation
      # - Multiple action buttons with primary/secondary styling
      # - Responsive mobile/desktop layouts
      # - Dark mode support
      # - Accessible semantic HTML
      #
      # ## Usage
      # ```ruby
      # render Panda::Core::Admin::PageHeaderComponent.new(
      #   title: "Back End Developer",
      #   breadcrumbs: [
      #     { text: "Jobs", href: "/admin/jobs" },
      #     { text: "Engineering", href: "/admin/jobs/engineering" }
      #   ]
      # ) do |header|
      #   header.button(text: "Edit", variant: :secondary, href: "/admin/jobs/1/edit")
      #   header.button(text: "Publish", variant: :primary, href: "/admin/jobs/1/publish")
      # end
      # ```
      #
      # @label Page Header
      # @display bg_color "#ffffff"
      # @display viewport_width "1000px"
      class PageHeaderComponentPreview < Lookbook::Preview
        # @!group Basic Examples

        # Simple header with title only
        # @label Title Only
        def title_only
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "Back End Developer"
          )
        end

        # Header with breadcrumbs
        # @label With Breadcrumbs
        def with_breadcrumbs
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "Back End Developer",
            breadcrumbs: [
              {text: "Jobs", href: "/admin/jobs"},
              {text: "Engineering", href: "/admin/jobs/engineering"},
              {text: "Back End Developer", href: "/admin/jobs/engineering/1"}
            ]
          )
        end

        # Header with single action button
        # @label Single Action
        def single_action
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "User Profile",
            breadcrumbs: [
              {text: "Users", href: "/admin/users"},
              {text: "John Doe", href: "/admin/users/1"}
            ]
          ) do |header|
            header.button(text: "Edit Profile", variant: :primary, href: "/admin/users/1/edit")
          end
        end

        # Header with multiple actions (Tailwind Plus pattern)
        # @label Multiple Actions
        def multiple_actions
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "Back End Developer",
            breadcrumbs: [
              {text: "Jobs", href: "/admin/jobs"},
              {text: "Engineering", href: "/admin/jobs/engineering"},
              {text: "Back End Developer", href: "/admin/jobs/engineering/1"}
            ]
          ) do |header|
            header.button(text: "Edit", variant: :secondary, href: "/admin/jobs/1/edit")
            header.button(text: "Publish", variant: :primary, href: "/admin/jobs/1/publish")
          end
        end

        # @!endgroup

        # @!group Real-World Examples

        # Blog post edit page header
        # @label Blog Post Editor
        def blog_post_editor
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "Building Modern Web Applications with Rails",
            breadcrumbs: [
              {text: "Posts", href: "/admin/posts"},
              {text: "Blog", href: "/admin/posts/blog"},
              {text: "2024", href: "/admin/posts/blog/2024"}
            ]
          ) do |header|
            header.button(text: "Preview", variant: :secondary, href: "/admin/posts/1/preview")
            header.button(text: "Save Draft", variant: :secondary, href: "/admin/posts/1/save")
            header.button(text: "Publish", variant: :primary, href: "/admin/posts/1/publish")
          end
        end

        # Product management page header
        # @label Product Manager
        def product_manager
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "MacBook Pro 16-inch",
            breadcrumbs: [
              {text: "Products", href: "/admin/products"},
              {text: "Electronics", href: "/admin/products/electronics"},
              {text: "Laptops", href: "/admin/products/electronics/laptops"}
            ]
          ) do |header|
            header.button(text: "Duplicate", variant: :secondary, href: "/admin/products/1/duplicate")
            header.button(text: "Edit", variant: :secondary, href: "/admin/products/1/edit")
            header.button(text: "Archive", variant: :danger, href: "/admin/products/1/archive")
          end
        end

        # User management page header
        # @label User Manager
        def user_manager
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "Jane Smith",
            breadcrumbs: [
              {text: "Users", href: "/admin/users"},
              {text: "Active Users", href: "/admin/users/active"}
            ]
          ) do |header|
            header.button(text: "Send Message", variant: :secondary, href: "/admin/users/1/message")
            header.button(text: "View Activity", variant: :secondary, href: "/admin/users/1/activity")
            header.button(text: "Edit Profile", variant: :primary, href: "/admin/users/1/edit")
          end
        end

        # @!endgroup

        # @!group Options

        # Header without breadcrumbs
        # @label No Breadcrumbs
        def no_breadcrumbs
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "Dashboard Overview"
          ) do |header|
            header.button(text: "Export Data", variant: :secondary, href: "/admin/export")
            header.button(text: "Refresh", variant: :primary, href: "/admin/refresh")
          end
        end

        # Long title truncation example
        # @label Long Title
        def long_title
          render Panda::Core::Admin::PageHeaderComponent.new(
            title: "This is a Very Long Title That Demonstrates How Text Truncation Works in Responsive Layouts",
            breadcrumbs: [
              {text: "Content", href: "/admin/content"},
              {text: "Articles", href: "/admin/content/articles"}
            ]
          ) do |header|
            header.button(text: "Edit", variant: :secondary, href: "/edit")
            header.button(text: "Publish", variant: :primary, href: "/publish")
          end
        end

        # @!endgroup
      end
    end
  end
end
