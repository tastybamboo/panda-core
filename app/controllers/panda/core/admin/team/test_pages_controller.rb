# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module Team
        # Test-only controller for nested navigation testing
        # Provides simple pages to test active state detection
        class TestPagesController < BaseController
          def overview
            add_breadcrumb "Team", "#"
            add_breadcrumb "Overview", admin_team_overview_path
            render inline: "<h1>Team Overview</h1><p>Test page for nested navigation</p>", layout: "panda/core/admin"
          end

          def members
            add_breadcrumb "Team", "#"
            add_breadcrumb "Members", admin_team_members_path
            render inline: "<h1>Team Members</h1><p>Test page for nested navigation</p>", layout: "panda/core/admin"
          end

          def calendar
            add_breadcrumb "Team", "#"
            add_breadcrumb "Calendar", admin_team_calendar_path
            render inline: "<h1>Team Calendar</h1><p>Test page for nested navigation</p>", layout: "panda/core/admin"
          end

          def settings
            add_breadcrumb "Team", "#"
            add_breadcrumb "Settings", admin_team_settings_path
            render inline: "<h1>Team Settings</h1><p>Test page for nested navigation</p>", layout: "panda/core/admin"
          end
        end
      end
    end
  end
end
