# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Panel
      class PanelComponentPreview < ViewComponent::Preview
        # Basic panel with default styling
        # @label Default
        def default
          render Panda::Core::Admin::PanelComponent.new do
            "This is a basic panel with some content inside."
          end
        end

        # Panel with rich content
        # @label With Content
        def with_content
          render Panda::Core::Admin::PanelComponent.new do
            <<~HTML.html_safe
              <h3 class="text-lg font-semibold mb-2">Panel Title</h3>
              <p class="text-gray-600 mb-4">This panel contains multiple elements including headings, paragraphs, and lists.</p>
              <ul class="list-disc list-inside space-y-1">
                <li>First item</li>
                <li>Second item</li>
                <li>Third item</li>
              </ul>
            HTML
          end
        end

        # Nested panels
        # @label Nested Panels
        def nested
          render Panda::Core::Admin::PanelComponent.new do
            <<~HTML.html_safe
              <h3 class="text-lg font-semibold mb-4">Outer Panel</h3>
              #{render(Panda::Core::Admin::PanelComponent.new) { "Inner panel content" }}
            HTML
          end
        end
      end
    end
  end
end
