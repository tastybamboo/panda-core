# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Users", type: :request do
  let(:admin_user) { create_admin_user }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "GET /admin/users" do
    it "renders the users index" do
      get "/admin/users"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(admin_user.name)
    end

    it "filters by search" do
      Panda::Core::User.create!(name: "Alice Wonderland", email: "alice-search@example.com")
      get "/admin/users", params: {search: "Alice"}
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alice Wonderland")
    end

    it "filters by status" do
      get "/admin/users", params: {status: "enabled"}
      expect(response).to have_http_status(:ok)
    end

    it "filters by role" do
      get "/admin/users", params: {role: "admin"}
      expect(response).to have_http_status(:ok)
    end

    it "supports sorting" do
      get "/admin/users", params: {sort: "name", direction: "desc"}
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/users/:id" do
    it "renders the user show page" do
      get "/admin/users/#{admin_user.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(admin_user.name)
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "renders the edit form" do
      get "/admin/users/#{admin_user.id}/edit"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates the user" do
      target = Panda::Core::User.create!(name: "Bob", email: "bob-update@example.com")
      patch "/admin/users/#{target.id}", params: {user: {name: "Robert"}}
      expect(response).to redirect_to("/admin/users")
      expect(target.reload.name).to eq("Robert")
    end

    it "re-renders the edit page with breadcrumbs when the update is invalid" do
      target = Panda::Core::User.create!(name: "Bob", email: "bob-invalid@example.com")

      patch "/admin/users/#{target.id}", params: {user: {email: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Users")
      expect(response.body).to include("Edit")
      expect(response.body).to include("Email")
      expect(target.reload.email).to eq("bob-invalid@example.com")
    end
  end

  describe "POST /admin/users/invite" do
    it "invites a new user" do
      expect {
        post "/admin/users/invite", params: {email: "newuser-invite@example.com", name: "New User"}
      }.to change(Panda::Core::User, :count).by(1)
      expect(response).to redirect_to("/admin/users")
      expect(flash[:success]).to include("newuser-invite@example.com")
    end

    it "rejects duplicate email" do
      Panda::Core::User.create!(name: "Existing", email: "existing-invite@example.com")
      post "/admin/users/invite", params: {email: "existing-invite@example.com", name: "Duplicate"}
      expect(response).to redirect_to("/admin/users")
      expect(flash[:error]).to be_present
    end
  end

  describe "PATCH /admin/users/:id/enable" do
    it "enables a disabled user" do
      target = Panda::Core::User.create!(name: "Disabled", email: "disabled-user@example.com", enabled: false)
      patch "/admin/users/#{target.id}/enable"
      expect(response).to redirect_to("/admin/users/#{target.id}")
      expect(target.reload.enabled).to be true
    end
  end

  describe "PATCH /admin/users/:id/disable" do
    it "disables another user" do
      target = Panda::Core::User.create!(name: "Target", email: "target-user@example.com", enabled: true)
      patch "/admin/users/#{target.id}/disable"
      expect(response).to redirect_to("/admin/users/#{target.id}")
      expect(target.reload.enabled).to be false
    end

    it "prevents disabling yourself" do
      patch "/admin/users/#{admin_user.id}/disable"
      expect(response).to redirect_to("/admin/users/#{admin_user.id}")
      expect(flash[:error]).to include("cannot disable your own account")
      expect(admin_user.reload.enabled).to be true
    end
  end

  describe "POST /admin/users/bulk_action" do
    it "enables the selected users" do
      disabled_user = Panda::Core::User.create!(name: "Disabled", email: "bulk-enable@example.com", enabled: false)

      post "/admin/users/bulk_action", params: {bulk_action: "enable", user_ids: [disabled_user.id]}

      expect(response).to redirect_to("/admin/users")
      expect(flash[:success]).to eq("1 user(s) enabled.")
      expect(disabled_user.reload.enabled).to be true
    end

    it "disables selected users except the current user" do
      other_user = Panda::Core::User.create!(name: "Other User", email: "bulk-disable@example.com", enabled: true)

      post "/admin/users/bulk_action", params: {bulk_action: "disable", user_ids: [admin_user.id, other_user.id]}

      expect(response).to redirect_to("/admin/users")
      expect(flash[:success]).to eq("1 user(s) disabled (excluding yourself).")
      expect(admin_user.reload.enabled).to be true
      expect(other_user.reload.enabled).to be false
    end

    it "rejects requests without any valid user ids" do
      post "/admin/users/bulk_action", params: {bulk_action: "enable", user_ids: ["not-a-uuid"]}

      expect(response).to redirect_to("/admin/users")
      expect(flash[:alert]).to eq("No valid users selected.")
    end

    it "rejects unknown bulk actions" do
      target = Panda::Core::User.create!(name: "Target", email: "bulk-unknown@example.com", enabled: true)

      post "/admin/users/bulk_action", params: {bulk_action: "archive", user_ids: [target.id]}

      expect(response).to redirect_to("/admin/users")
      expect(flash[:error]).to eq("Unknown action.")
      expect(target.reload.enabled).to be true
    end
  end

  describe "GET /admin/users/:id/activity" do
    it "renders the activity page" do
      get "/admin/users/#{admin_user.id}/activity"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/users/:id/sessions" do
    it "renders the sessions page" do
      get "/admin/users/#{admin_user.id}/sessions"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /admin/users/:id/sessions/:session_id" do
    it "revokes the selected session" do
      user_session = Panda::Core::UserSession.create!(
        user: admin_user,
        session_id: "request-session-123",
        active: true,
        last_active_at: Time.current
      )

      delete "/admin/users/#{admin_user.id}/sessions/#{user_session.id}"

      expect(response).to redirect_to("/admin/users/#{admin_user.id}")
      expect(flash[:success]).to eq("Session revoked.")
      expect(user_session.reload.active).to be false
      expect(user_session.revoked_at).to be_present
      expect(user_session.revoked_by).to eq(admin_user)
    end
  end
end
