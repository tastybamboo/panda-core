# frozen_string_literal: true

module Panda
  module Core
    module Shared
      # Header component for HTML document head
      # Handles title, meta tags, stylesheets, and JavaScript
      class HeaderComponent < ViewComponent::Base
        def initialize(html_class: "", body_class: "", **attrs)
          super()
          @html_class = html_class
          @body_class = body_class
        end

        attr_reader :html_class, :body_class
      end
    end
  end
end
