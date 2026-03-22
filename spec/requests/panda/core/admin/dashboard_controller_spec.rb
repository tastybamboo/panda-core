# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Dashboard", type: :request do
  let(:admin_user) { create_admin_user }

  describe "GET /admin" do
    context "when authenticated" do
      before { post "/admin/test_sessions", params: {user_id: admin_user.id} }

      it "renders the dashboard" do
        get "/admin"
        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get "/admin"
        expect(response).to redirect_to("/admin/login")
      end
    end
  end
end
