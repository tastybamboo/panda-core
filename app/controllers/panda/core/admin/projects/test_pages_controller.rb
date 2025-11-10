# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module Projects
        # Test-only controller for nested navigation testing
        # Provides simple pages to test active state detection
        class TestPagesController < BaseController
          def index
            add_breadcrumb "Projects", admin_projects_path
            render inline: "<h1>All Projects</h1><p>Test page for nested navigation</p>", layout: "panda/core/admin"
          end

          def active
            add_breadcrumb "Projects", admin_projects_path
            add_breadcrumb "Active", admin_projects_active_path
            render inline: "<h1>Active Projects</h1><p>Test page for nested navigation</p>", layout: "panda/core/admin"
          end

          def archived
            add_breadcrumb "Projects", admin_projects_path
            add_breadcrumb "Archived", admin_projects_archived_path
            render inline: "<h1>Archived Projects</h1><p>Test page for nested navigation</p>", layout: "panda/core/admin"
          end
        end
      end
    end
  end
end
