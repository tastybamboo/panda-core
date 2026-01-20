# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Sidebar navigation component for admin pages
      # Displays hierarchical navigation with toggle for nested items
      class SidebarComponent < Panda::Core::Base
        def initialize(user:, **attrs)
          @user = user
          super(**attrs)
        end

        attr_reader :user

        private

        def default_attrs
          {class: "flex flex-col flex-1"}
        end
      end
    end
  end
end
