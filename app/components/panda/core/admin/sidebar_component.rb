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

        def safe_html(value)
          raw = value.respond_to?(:call) ? value.call : value
          helpers.sanitize(raw, tags: %w[svg path ellipse circle rect line polyline polygon g defs use
                                         span a i div img br strong em b], attributes: %w[
            viewBox fill stroke stroke-width stroke-linecap stroke-linejoin opacity cx cy rx ry r
            x y x1 y1 x2 y2 width height d points transform xmlns class href style id
            data-turbo-track rel
          ])
        end

        private

        def default_attrs
          {class: "flex flex-col flex-1"}
        end
      end
    end
  end
end
