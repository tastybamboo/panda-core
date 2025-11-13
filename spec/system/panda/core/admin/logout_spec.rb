# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin logout", type: :system do
  let(:admin_user) { create_admin_user }

  before do
    login_with_google(admin_user)
  end

  describe "logging out" do
    it "logs out the user and redirects to login page", js: true do
      visit "/admin"
      expect(page).to have_content("Dashboard")

      # Open user menu and click logout
      find("button", text: admin_user.name).click
      click_on "Logout"

      # Should redirect to login page
      expect(page).to have_current_path("/admin/login")
      expect(page).to have_content("Successfully logged out")
    end

    it "clears the session after logout", js: true do
      visit "/admin"
      expect(page).to have_content("Dashboard")

      # Open user menu and click logout
      find("button", text: admin_user.name).click
      click_on "Logout"

      # Try to visit admin page after logout
      visit "/admin"

      # Should redirect to login page since not authenticated
      expect(page).to have_current_path("/admin/login")
    end

    it "shows login page after logout without admin content", js: true do
      visit "/admin"
      expect(page).to have_content("Dashboard")

      # Open user menu and click logout
      find("button", text: admin_user.name).click
      click_on "Logout"

      # Should be on login page
      expect(page).to have_current_path("/admin/login")

      # Should not have admin navigation or user info
      expect(page).not_to have_content("Dashboard")
      expect(page).not_to have_content(admin_user.name)
    end

    it "allows logging in again after logout", js: true do
      visit "/admin"

      # Open user menu and click logout
      find("button", text: admin_user.name).click
      click_on "Logout"

      # Should be able to login again
      login_with_google(admin_user)
      visit "/admin"

      expect(page).to have_content("Dashboard")
      expect(page).to have_content(admin_user.name)
    end
  end

  describe "logout notifications" do
    it "triggers user_logout notification", js: true do
      events = []
      ActiveSupport::Notifications.subscribe("panda.core.user_logout") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      visit "/admin"

      # Open user menu and click logout
      find("button", text: admin_user.name).click
      click_on "Logout"

      expect(events.size).to eq(1)
    end
  end
end
