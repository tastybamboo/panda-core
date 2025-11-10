# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin authentication", type: :system do
  let(:admin_user) { create_admin_user }
  let(:regular_user) { create_regular_user }

  describe "OAuth provider authentication" do
    context "with Google" do
      it "logs in admin successfully using test endpoint" do
        login_with_google(admin_user)
        # Verify we're logged in (either at /admin or wherever the app redirects)
        expect(["/admin", "/admin/cms"]).to include(page.current_path)
      end

      it "prevents non-admin access" do
        login_with_google(regular_user, expect_success: false)
        expect(page).to have_current_path("/admin/login")
        expect(page).to have_content("You do not have permission to access the admin area")
      end
    end

    context "with GitHub" do
      it "logs in admin successfully using test endpoint" do
        login_with_github(admin_user)
        expect(["/admin", "/admin/cms"]).to include(page.current_path)
      end
    end

    context "with Microsoft" do
      it "logs in admin successfully using test endpoint" do
        login_with_microsoft(admin_user)
        expect(["/admin", "/admin/cms"]).to include(page.current_path)
      end
    end
  end

  describe "authentication errors" do
    it "handles invalid credentials" do
      # Silence OmniAuth logger for this test since we're intentionally causing an error
      original_logger = OmniAuth.config.logger
      OmniAuth.config.logger = Logger.new(nil)

      begin
        # Mock invalid credentials (don't clear config - providers are pre-configured)
        OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

        # Visit the callback URL directly (simulating failed OAuth)
        visit "/admin/auth/google_oauth2/callback"

        # Should redirect back to login with error message
        expect(page).to have_current_path("/admin/login")
        # The flash message will appear at the top
        expect(page).to have_content("Authentication failed")
      ensure
        # Restore original logger
        OmniAuth.config.logger = original_logger
      end
    end
  end
end
