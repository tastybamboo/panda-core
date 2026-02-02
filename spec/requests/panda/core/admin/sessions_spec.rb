# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Sessions", type: :request do
  let(:admin_user) { create_admin_user }
  let(:regular_user) { create_regular_user }

  # ============================================================================
  # Test Session Controller Tests (Test-Only Endpoint)
  # ============================================================================

  describe "POST /admin/test_sessions" do
    context "when user is not an admin" do
      it "sets flash alert and redirects to login" do
        post "/admin/test_sessions", params: {user_id: regular_user.id}

        # Test flash directly - this works in request specs!
        expect(flash[:alert]).to eq("You do not have permission to access the admin area.")
        expect(response).to redirect_to("/admin/login")
        expect(session[:user_id]).to be_nil
      end
    end

    context "when user is an admin" do
      it "creates session and redirects to admin area" do
        post "/admin/test_sessions", params: {user_id: admin_user.id}

        expect(session[:user_id]).to eq(admin_user.id)
        expect(response).to redirect_to("/admin")
        expect(flash[:alert]).to be_nil
      end

      it "supports custom redirect path via return_to parameter" do
        post "/admin/test_sessions", params: {user_id: admin_user.id, return_to: "/admin/custom"}

        expect(session[:user_id]).to eq(admin_user.id)
        expect(response).to redirect_to("/admin/custom")
      end
    end

    context "when user does not exist" do
      it "returns 404 with error message" do
        post "/admin/test_sessions", params: {user_id: "nonexistent-id"}

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("User not found")
      end
    end
  end

  describe "GET /admin/test_login/:user_id" do
    context "when user is an admin" do
      it "creates session and redirects to admin area" do
        get "/admin/test_login/#{admin_user.id}"

        expect(session[:user_id]).to eq(admin_user.id)
        expect(response).to redirect_to("/admin")
      end

      it "respects return_to query parameter" do
        get "/admin/test_login/#{admin_user.id}?return_to=/admin/custom"

        expect(session[:user_id]).to eq(admin_user.id)
        expect(response).to redirect_to("/admin/custom")
      end
    end

    context "when user is not an admin" do
      it "sets flash alert and redirects to login" do
        get "/admin/test_login/#{regular_user.id}"

        expect(flash[:alert]).to eq("You do not have permission to access the admin area.")
        expect(response).to redirect_to("/admin/login")
        expect(session[:user_id]).to be_nil
      end
    end
  end

  # ============================================================================
  # OAuth Controller Tests (Production Authentication Flow)
  # ============================================================================

  describe "POST /admin/auth/:provider/callback" do
    let!(:original_providers) { Panda::Core.config.authentication_providers.dup }

    before do
      OmniAuth.config.test_mode = true
      # Enable the provider in config
      Panda::Core.config.authentication_providers = {
        google_oauth2: {
          client_id: "test_client_id",
          client_secret: "test_client_secret"
        }
      }
    end

    after do
      clear_omniauth_config
      Panda::Core.config.authentication_providers = original_providers
    end

    context "when user is not an admin" do
      it "sets error flash and redirects to login" do
        mock_oauth_for_user(regular_user, provider: :google_oauth2)

        # Set the OmniAuth env variable for the request
        post "/admin/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}

        # Test flash directly - works in request specs!
        expect(flash[:error]).to eq("You do not have permission to access the admin area")
        expect(response).to redirect_to(panda_core.admin_login_path)
        expect(session[:user_id]).to be_nil
      end
    end

    context "when user is an admin" do
      it "sets success flash and creates session" do
        mock_oauth_for_user(admin_user, provider: :google_oauth2)

        post "/admin/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}

        expect(flash[:success]).to eq("Successfully logged in as #{admin_user.name}")
        expect(session[:user_id]).to eq(admin_user.id)
        expect(response).to redirect_to(panda_core.admin_root_path)
      end

      it "creates user if they don't exist yet" do
        expect {
          OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
            provider: "google_oauth2",
            uid: "new_admin_uid_999",
            info: {
              email: "newadmin@example.com",
              name: "New Admin",
              first_name: "New",
              last_name: "Admin"
            }
          })

          post "/admin/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}
        }.to change(Panda::Core::User, :count).by(1)

        new_user = Panda::Core::User.find_by(email: "newadmin@example.com")
        expect(new_user).to be_present
        expect(session[:user_id]).to eq(new_user.id)
      end
    end

    context "when authentication fails" do
      it "sets error flash and redirects to login" do
        allow(Panda::Core::User).to receive(:find_or_create_from_auth_hash).and_raise(StandardError.new("OAuth error"))

        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
          provider: "google_oauth2",
          uid: "123",
          info: {email: "test@example.com", name: "Test User"}
        })

        post "/admin/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}

        expect(flash[:error]).to match(/Authentication failed/)
        expect(response).to redirect_to(panda_core.admin_login_path)
      end
    end

    context "when provider is not enabled" do
      it "sets error flash and redirects to login" do
        Panda::Core.config.authentication_providers = {}

        mock_oauth_for_user(admin_user, provider: :google_oauth2)

        post "/admin/auth/google_oauth2/callback", env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}

        expect(flash[:error]).to eq("Authentication provider not enabled")
        expect(response).to redirect_to(panda_core.admin_login_path)
      end
    end
  end

  describe "GET /admin/auth/failure" do
    it "sets error flash with failure message" do
      get "/admin/auth/failure", params: {message: "invalid_credentials", strategy: "google_oauth2"}

      expect(flash[:error]).to eq("Authentication failed: invalid_credentials")
      expect(response).to redirect_to(panda_core.admin_login_path)
    end

    it "handles missing message parameter" do
      get "/admin/auth/failure"

      expect(flash[:error]).to eq("Authentication failed: Authentication failed")
      expect(response).to redirect_to(panda_core.admin_login_path)
    end
  end

  describe "DELETE /admin/logout" do
    before do
      # Set up an admin session
      sign_in_as(admin_user)
    end

    it "clears the session and redirects to login" do
      # Session was set by sign_in_as in before block
      delete "/admin/logout"

      # Verify session is cleared and redirected
      expect(flash[:success]).to eq("Successfully logged out")
      expect(response).to redirect_to(panda_core.admin_login_path)

      # Verify user is logged out by trying to access protected page
      get "/admin"
      expect(response).to redirect_to(panda_core.admin_login_path)
    end
  end
end
