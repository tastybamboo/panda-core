require "rails_helper"

RSpec.describe Panda::Core::User, type: :model do

  describe "validations" do
    subject { described_class.new(name: "Test User", email: "test@example.com") }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "OAuth authentication" do
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

    context ".find_or_create_from_auth_hash" do
      it "creates a new user if not found" do
        expect {
          described_class.find_or_create_from_auth_hash(auth_hash)
        }.to change(described_class, :count).by(1)
      end

      it "finds existing user by email" do
        existing_user = described_class.create!(email: "test@example.com", name: "Existing User")
        user = described_class.find_or_create_from_auth_hash(auth_hash)
        expect(user).to eq(existing_user)
      end

      it "updates user attributes from auth hash" do
        user = described_class.find_or_create_from_auth_hash(auth_hash)
        expect(user.name).to eq("Test User")
        expect(user.image_url).to eq("https://example.com/image.jpg")
      end
    end
  end

  describe "#admin?" do
    it "returns true for admin users" do
      user = described_class.new(email: "admin@example.com", is_admin: true, name: "Admin User")
      expect(user.admin?).to be true
    end

    it "returns false for non-admin users" do
      user = described_class.new(email: "user@example.com", is_admin: false, name: "Regular User")
      expect(user.admin?).to be false
    end
  end
end
