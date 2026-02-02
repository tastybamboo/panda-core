# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin My Profile Logins", type: :system do
  let!(:admin_user) { create_admin_user }

  before do
    login_with_google(admin_user)
  end

  describe "navigation to Login & Security page" do
    it "shows Login & Security link in user menu", js: true do
      visit "/admin"

      # Open user menu
      find("button", text: admin_user.name).click

      within("#user-menu") do
        expect(page).to have_link("Login & Security", visible: :all)
      end
    end

    it "navigates to Login & Security page when clicked", js: true do
      visit "/admin"

      # Open user menu and click Login & Security
      find("button", text: admin_user.name).click
      click_on "Login & Security"

      expect(page).to have_current_path("/admin/my_profile/logins")
      expect(page).to have_content("Login & Security")
    end

    it "highlights Login & Security as active when on that page", js: true do
      visit "/admin/my_profile/logins"

      # The user menu is already open when one of its items is active,
      # so we don't need to click the button to open it
      within("#user-menu") do
        logins_link = find("a", text: "Login & Security")
        expect(logins_link[:class]).to include("bg-primary-500")
        expect(logins_link[:class]).to include("text-white")
      end
    end
  end

  describe "page content" do
    before do
      visit "/admin/my_profile/logins"
    end

    it "displays the page heading", js: true do
      expect(page).to have_content("Login & Security")
    end

    it "displays breadcrumbs", js: true do
      expect(page).to have_link("My Profile")
      expect(page).to have_content("Login & Security")
    end

    it "displays Connected Accounts panel", js: true do
      expect(page).to have_content("Connected Accounts")
      expect(page).to have_content("Manage your OAuth authentication providers")
    end

    it "displays Login History panel", js: true do
      expect(page).to have_content("Login History")
      expect(page).to have_content("Recent login activity for your account")
      expect(page).to have_content("Login history tracking will be implemented in a future release")
    end

    it "displays Two-Factor Authentication panel", js: true do
      expect(page).to have_content("Two-Factor Authentication")
      expect(page).to have_content("Add an extra layer of security to your account")
      expect(page).to have_content("Two-factor authentication will be available in a future release")
      expect(page).to have_link("GitHub Issue #34")
    end
  end

  describe "Connected Accounts" do
    # Explicitly set providers to protect against config pollution from other tests.
    # The Puma server runs in a separate thread (same process), so config changes
    # made here are visible to the server immediately.
    let!(:original_providers) { Panda::Core.config.authentication_providers.dup }

    before do
      Panda::Core.config.authentication_providers = {
        google_oauth2: {client_id: "test", client_secret: "test"},
        github: {client_id: "test", client_secret: "test"},
        microsoft_graph: {client_id: "test", client_secret: "test"}
      }
      visit "/admin/my_profile/logins"
    end

    after do
      Panda::Core.config.authentication_providers = original_providers
    end

    it "displays all enabled providers", js: true do
      expect(page).to have_content("Microsoft")
      expect(page).to have_content("Google")
      expect(page).to have_content("GitHub")
    end

    it "displays provider icons", js: true do
      # FontAwesome JS replaces <i> tags with <svg> elements
      expect(page).to have_css("svg[data-prefix='fab'][data-icon='microsoft']")
      expect(page).to have_css("svg[data-prefix='fab'][data-icon='google']")
      expect(page).to have_css("svg[data-prefix='fab'][data-icon='github']")
    end

    it "shows not connected status for all providers", js: true do
      # Since we don't track which provider the user logged in with yet,
      # all providers should show as "Not connected"
      google_section = find("h3", text: "Google").ancestor("div.flex.items-center.justify-between")
      within(google_section) do
        expect(page).to have_content("Not connected")
        expect(page).not_to have_css("svg[data-icon='check-circle']")
      end
    end

    it "shows disabled Connect button for providers", js: true do
      google_section = find("h3", text: "Google").ancestor("div.flex.items-center.justify-between")
      within(google_section) do
        link = find("a", text: "Connect")
        expect(link[:title]).to eq("OAuth re-connection coming soon")
      end
    end
  end
end
