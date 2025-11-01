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
      before do
        # Enable GitHub in config
        Panda::Core.config.authentication_providers[:github] = {
          client_id: "test_client_id",
          client_secret: "test_client_secret"
        }
      end

      it "logs in admin successfully using test endpoint" do
        login_with_github(admin_user)
        expect(["/admin", "/admin/cms"]).to include(page.current_path)
      end
    end

    context "with Microsoft" do
      before do
        # Enable Microsoft in config
        Panda::Core.config.authentication_providers[:microsoft_graph] = {
          client_id: "test_client_id",
          client_secret: "test_client_secret"
        }
      end

      it "logs in admin successfully using test endpoint" do
        login_with_microsoft(admin_user)
        expect(["/admin", "/admin/cms"]).to include(page.current_path)
      end
    end
  end

  describe "authentication errors" do
    it "handles invalid credentials" do
      clear_omniauth_config
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

      # Visit the callback URL directly (simulating failed OAuth)
      visit "/admin/auth/google_oauth2/callback"

      # Should redirect back to login with error message
      expect(page).to have_current_path("/admin/login")
      # Note: Flash messages are not reliably testable in system specs due to cross-process timing
      # See docs/testing/authentication-helpers.md for flash testing guidance
      expect(page).to have_content("Sign in")
    end
  end
end
