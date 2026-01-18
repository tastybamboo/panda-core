# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Breadcrumbs navigation component for admin pages
      # Displays hierarchical navigation starting from admin home
      class BreadcrumbsComponent < Panda::Core::Base
        def initialize(breadcrumbs: [], **attrs)
          @breadcrumbs = breadcrumbs
          super(**attrs)
        end

        attr_reader :breadcrumbs

        private

        def default_attrs
          {
            class: "px-4 w-full sm:px-6 py-2.5"
          }
        end
      end
    end
  end
end
