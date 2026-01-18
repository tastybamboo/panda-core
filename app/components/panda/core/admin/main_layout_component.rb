# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Main admin layout component
      # Handles the full admin page layout with sidebar, header, and main content
      class MainLayoutComponent < ViewComponent::Base
        def initialize(user:, breadcrumbs: [], **attrs)
          super()
          @user = user
          @breadcrumbs = breadcrumbs
        end

        attr_reader :user, :breadcrumbs
      end
    end
  end
end
