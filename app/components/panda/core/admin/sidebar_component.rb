# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Sidebar navigation component for admin pages
      # Displays hierarchical navigation with toggle for nested items.
      # Supports optional section grouping via the :section key on nav items.
      class SidebarComponent < Panda::Core::Base
        def initialize(user:, **attrs)
          @user = user
          super(**attrs)
        end

        attr_reader :user

        def admin_logo
          Panda::Core.config.admin_logo
        end

        def admin_settings_path
          Panda::Core.config.admin_settings_path
        end

        def sectioned?(items)
          items.any? { |item| item[:section].present? }
        end

        def group_by_section(items)
          items.group_by { |item| item[:section] || "" }
        end

        private

        def default_attrs
          {class: "flex flex-col flex-1"}
        end
      end
    end
  end
end
