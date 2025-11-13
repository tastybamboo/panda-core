# frozen_string_literal: true

require "system_helper"

RSpec.describe "Nested navigation", type: :system do
  let(:admin_user) { create_admin_user }

  before do
    login_with_google(admin_user)
  end

  context "with nested navigation items" do
    before do
      # Configure navigation with nested items
      Panda::Core.configure do |config|
        config.admin_navigation_items = ->(user) {
          [
            {
              label: "Dashboard",
              path: "/admin",
              icon: "fa-solid fa-house"
            },
            {
              label: "Team",
              icon: "fa-solid fa-users",
              children: [
                {label: "Overview", path: "/admin/team/overview"},
                {label: "Members", path: "/admin/team/members"},
                {label: "Calendar", path: "/admin/team/calendar"},
                {label: "Settings", path: "/admin/team/settings"}
              ]
            },
            {
              label: "Projects",
              icon: "fa-solid fa-folder",
              children: [
                {label: "All Projects", path: "/admin/projects"},
                {label: "Active", path: "/admin/projects/active"},
                {label: "Archived", path: "/admin/projects/archived"}
              ]
            }
          ]
        }
      end
    end

    it "displays top-level navigation items" do
      visit "/admin"

      expect(page).to have_content("Dashboard")
      expect(page).to have_content("Team")
      expect(page).to have_content("Projects")
    end

    it "collapses nested items by default" do
      visit "/admin"

      # Wait for Stimulus controllers to initialize
      expect(page).to have_css("[data-controller='navigation-toggle']", wait: 2)

      # Sub-menu items should be hidden initially (checking visibility, not just DOM presence)
      expect(page).not_to have_css("a", text: "Overview", visible: true)
      expect(page).not_to have_css("a", text: "Members", visible: true)
      expect(page).not_to have_css("a", text: "Calendar", visible: true)
    end

    it "expands nested items when clicked", js: true do
      visit "/admin"

      # Click the Team button to expand
      find("button", text: "Team").click

      # Sub-menu items should now be visible
      expect(page).to have_content("Overview")
      expect(page).to have_content("Members")
      expect(page).to have_content("Calendar")
      expect(page).to have_content("Settings")
    end

    it "collapses nested items when clicked again", js: true do
      visit "/admin"

      # Wait for Stimulus controllers to initialize
      expect(page).to have_css("[data-controller='navigation-toggle']", wait: 2)

      # Expand the menu
      team_button = find("button", text: "Team")
      team_button.click
      expect(page).to have_css("a", text: "Overview", visible: true)

      # Collapse the menu
      team_button.click

      # Wait for collapse animation/transition
      sleep 0.3

      # Sub-menu items should be hidden again
      expect(page).not_to have_css("a", text: "Overview", visible: true)
    end

    it "rotates chevron icon when expanding", js: true do
      visit "/admin"

      # Find the chevron icon using data attribute
      team_button = find("button", text: "Team")
      chevron = team_button.find("[data-navigation-toggle-target='icon']", visible: :all)

      # Initially should not be rotated
      expect(chevron[:class]).not_to include("rotate-90")

      # Click to expand
      team_button.click

      # Wait for JavaScript to add the rotate-90 class
      expect(page).to have_css("[data-navigation-toggle-target='icon'].rotate-90", wait: 2)

      # Verify the chevron is now rotated
      chevron = team_button.find("[data-navigation-toggle-target='icon']", visible: :all)
      expect(chevron[:class]).to include("rotate-90")
    end

    it "can expand multiple menus simultaneously", js: true do
      visit "/admin"

      # Expand both menus
      find("button", text: "Team").click
      find("button", text: "Projects").click

      # Both should show their sub-items
      expect(page).to have_content("Overview")
      expect(page).to have_content("Members")
      expect(page).to have_content("All Projects")
      expect(page).to have_content("Active")
    end

    it "updates aria-expanded attribute", js: true do
      visit "/admin"

      team_button = find("button", text: "Team")

      # Initially should be collapsed
      expect(team_button["aria-expanded"]).to eq("false")

      # Click to expand
      team_button.click

      # Should now be expanded
      expect(team_button["aria-expanded"]).to eq("true")
    end
  end

  context "with active child item" do
    before do
      # Configure navigation with nested items using real routes
      Panda::Core.configure do |config|
        config.admin_navigation_items = ->(user) {
          [
            {
              label: "Dashboard",
              path: "/admin",
              icon: "fa-solid fa-house"
            },
            {
              label: "Settings",
              icon: "fa-solid fa-gear",
              children: [
                {label: "Site Settings", path: "/admin/settings"},
                {label: "My Profile", path: "/admin/my_profile"}
              ]
            }
          ]
        }
      end
    end

    it "expands parent menu automatically when child is active", js: true do
      visit "/admin/settings"

      # The Settings menu should be automatically expanded
      expect(page).to have_content("Site Settings")
      expect(page).to have_content("My Profile")

      # The Settings link should be visible and highlighted
      settings_link = find("a", text: "Site Settings")
      expect(settings_link[:class]).to include("bg-mid")
    end

    it "highlights parent menu when child is active", js: true do
      visit "/admin/my_profile"

      # The Settings button should have active styling
      settings_button = find("button", text: "Settings")
      expect(settings_button[:class]).to include("bg-mid")
    end
  end
end
