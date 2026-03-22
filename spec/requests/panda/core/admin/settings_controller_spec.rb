# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Settings", type: :request do
  let(:admin_user) { create_admin_user }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "GET /admin/settings" do
    it "renders the settings page" do
      get "/admin/settings"
      expect(response).to have_http_status(:ok)
    end
  end
end
