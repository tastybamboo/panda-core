require "rails_helper"

RSpec.describe Panda::Core::Admin::SessionsController, type: :controller do
  routes { Panda::Core::Engine.routes }

  describe "GET #new" do
    it "renders the login page" do
      get :new
      expect(response).to have_http_status(:success)
    end

    it "includes developer provider in development mode" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("development"))
      Panda::Core.config.authentication_providers[:developer] = {options: {}}

      get :new

      expect(assigns(:providers)).to include(:developer)
    ensure
      Panda::Core.config.authentication_providers.delete(:developer)
    end

    it "excludes developer provider in production mode" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))
      Panda::Core.config.authentication_providers[:developer] = {options: {}}

      get :new

      expect(assigns(:providers)).not_to include(:developer)
    ensure
      Panda::Core.config.authentication_providers.delete(:developer)
    end
  end

  describe "GET #create" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: "google_oauth2",
        uid: "12345",
        info: {
          email: "test@example.com",
          name: "Test User",
          image: "https://example.com/image.jpg"
        }
      })
    end

    before do
      request.env["omniauth.auth"] = auth_hash
    end

    it "creates user and signs them in" do
      expect {
        get :create, params: {provider: "google_oauth2"}
      }.to change(Panda::Core::User, :count).by(1)

      expect(session[Panda::Core::ADMIN_SESSION_KEY]).to be_present
      expect(response).to redirect_to("/admin")
    end

    it "signs in existing user" do
      user = Panda::Core::User.create!(email: "test@example.com", name: "Existing User", admin: true)

      get :create, params: {provider: "google_oauth2"}

      expect(session[Panda::Core::ADMIN_SESSION_KEY]).to eq(user.id)
      expect(response).to redirect_to("/admin")
    end
  end

  describe "DELETE #destroy" do
    let(:user) { Panda::Core::User.create!(email: "test@example.com", name: "Test User", admin: true) }

    before do
      session[:user_id] = user.id
    end

    it "signs out the user" do
      delete :destroy

      expect(session[Panda::Core::ADMIN_SESSION_KEY]).to be_nil
      expect(response).to redirect_to("/admin/login")
    end
  end
end
