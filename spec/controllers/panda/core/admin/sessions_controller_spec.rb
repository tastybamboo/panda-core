require "rails_helper"

RSpec.describe Panda::Core::Admin::SessionsController, type: :controller do
  routes { Panda::Core::Engine.routes }

  describe "GET #new" do
    it "renders the login page" do
      get :new
      expect(response).to have_http_status(:success)
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

      expect(session[:user_id]).to be_present
      expect(response).to redirect_to("/admin")
    end

    it "signs in existing user" do
      user = Panda::Core::User.create!(email: "test@example.com", name: "Existing User", admin: true)

      get :create, params: {provider: "google_oauth2"}

      expect(session[:user_id]).to eq(user.id)
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

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to("/admin/login")
    end
  end
end
