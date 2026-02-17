# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FeatureFlagsController, type: :controller do
  routes { Panda::Core::Engine.routes }

  let(:user) { Panda::Core::User.create!(email: "admin@example.com", name: "Admin User", admin: true) }

  before do
    session[Panda::Core::ADMIN_SESSION_KEY] = user.id
  end

  describe "GET #index" do
    it "renders the index template" do
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
    end

    it "assigns all feature flags" do
      flag1 = Panda::Core::FeatureFlag.create!(key: "test.alpha", enabled: true)
      flag2 = Panda::Core::FeatureFlag.create!(key: "test.beta", enabled: false)

      get :index
      expect(assigns(:feature_flags)).to include(flag1, flag2)
    end

    it "groups flags by namespace" do
      Panda::Core::FeatureFlag.create!(key: "group_a.flag1")
      Panda::Core::FeatureFlag.create!(key: "group_a.flag2")
      Panda::Core::FeatureFlag.create!(key: "group_b.flag1")

      get :index
      groups = assigns(:grouped_flags)
      expect(groups.keys).to contain_exactly("group_a", "group_b")
      expect(groups["group_a"].size).to eq(2)
      expect(groups["group_b"].size).to eq(1)
    end

    it "requires authentication" do
      session.delete(Panda::Core::ADMIN_SESSION_KEY)
      get :index
      expect(response).to redirect_to("/admin/login")
    end
  end

  describe "PATCH #update" do
    let!(:flag) { Panda::Core::FeatureFlag.create!(key: "test.toggle", enabled: false) }

    it "toggles the flag state" do
      patch :update, params: {id: flag.id}
      expect(flag.reload.enabled).to be true
    end

    it "toggles enabled to disabled" do
      flag.update!(enabled: true)
      patch :update, params: {id: flag.id}
      expect(flag.reload.enabled).to be false
    end

    it "sets a success flash message" do
      patch :update, params: {id: flag.id}
      expect(flash[:success]).to include("test.toggle")
      expect(flash[:success]).to include("enabled")
    end

    it "redirects to the index" do
      patch :update, params: {id: flag.id}
      expect(response).to redirect_to("/admin/feature_flags")
    end

    it "requires authentication" do
      session.delete(Panda::Core::ADMIN_SESSION_KEY)
      patch :update, params: {id: flag.id}
      expect(response).to redirect_to("/admin/login")
    end
  end
end
