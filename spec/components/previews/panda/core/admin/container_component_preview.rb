# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Container
      class ContainerComponentPreview < Lookbook::Preview
        # Default container
        # @label Default
        def default
          render Panda::Core::Admin::ContainerComponent.new do
            "This content is wrapped in a container component."
          end
        end

        # Container with rich content
        # @label With Content
        def with_content
          render Panda::Core::Admin::ContainerComponent.new do
            <<~HTML.html_safe
              <h2 class="text-2xl font-bold mb-4">Container Title</h2>
              <p class="text-gray-700 mb-4">This container holds multiple elements with proper spacing and layout.</p>
              <div class="grid grid-cols-2 gap-4">
                <div class="bg-gray-100 p-4 rounded">Column 1</div>
                <div class="bg-gray-100 p-4 rounded">Column 2</div>
              </div>
            HTML
          end
        end
      end
    end
  end
end
