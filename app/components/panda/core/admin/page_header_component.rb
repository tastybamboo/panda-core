# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Page header component with title, optional breadcrumbs, and action buttons.
      #
      # Follows Tailwind UI Plus pattern for page headers with responsive layout
      # and support for multiple action buttons.
      #
      # @example Basic header with title only
      #   render Panda::Core::Admin::PageHeaderComponent.new(
      #     title: "Back End Developer"
      #   )
      #
      # @example Header with breadcrumbs
      #   render Panda::Core::Admin::PageHeaderComponent.new(
      #     title: "Back End Developer",
      #     breadcrumbs: [
      #       { text: "Jobs", href: "/admin/jobs" },
      #       { text: "Engineering", href: "/admin/jobs/engineering" },
      #       { text: "Back End Developer", href: "/admin/jobs/engineering/1" }
      #     ]
      #   )
      #
      # @example Header with action buttons using block
      #   render Panda::Core::Admin::PageHeaderComponent.new(
      #     title: "Back End Developer",
      #     breadcrumbs: breadcrumb_items
      #   ) do |header|
      #     header.button(text: "Edit", variant: :secondary, href: edit_path)
      #     header.button(text: "Publish", variant: :primary, href: publish_path)
      #   end
      #
      class PageHeaderComponent < Panda::Core::Base
        def initialize(title: "", breadcrumbs: nil, show_back: true, **attrs, &block)
          @title = title
          @breadcrumbs = breadcrumbs
          @show_back = show_back
          @buttons = []
          @setup_block = block
          super(**attrs)
        end

        attr_reader :title, :breadcrumbs, :show_back

        # Lazy accessor that ensures buttons are registered before returning them.
        # Supports two patterns:
        # 1. Block passed to new() - executed here (for tests)
        # 2. Block passed to render() - executed via content (for ERB templates)
        def buttons
          unless @buttons_registered
            if @setup_block
              @setup_block.call(self)
            else
              content
            end
            @buttons_registered = true
          end
          @buttons
        end

        # Define a button to be rendered in the header actions area
        #
        # @param text [String] Button text
        # @param variant [Symbol] Button variant (:primary or :secondary)
        # @param href [String] Link href
        # @param props [Hash] Additional button properties
        def button(text:, variant: :secondary, href: "#", **props)
          @buttons << {text: text, variant: variant, href: href, **props}
        end

        private

        def create_button(button_data, index)
          Panda::Core::UI::Button.new(
            text: button_data[:text],
            variant: button_data[:variant],
            href: button_data[:href],
            class: button_margin_class(index),
            **button_data.except(:text, :variant, :href)
          )
        end

        def button_margin_class(index)
          index.zero? ? "" : "ml-3"
        end
      end
    end
  end
end
