require "rails_helper"

RSpec.describe Panda::Core::User, type: :model do
  describe "associations" do
    it { should have_one_attached(:avatar) }
  end

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

      it "calls AttachAvatarService for new users with avatar" do
        expect(Panda::Core::AttachAvatarService).to receive(:call).with(
          user: an_instance_of(described_class),
          avatar_url: "https://example.com/image.jpg"
        )
        described_class.find_or_create_from_auth_hash(auth_hash)
      end

      it "calls AttachAvatarService for existing users when avatar URL changes" do
        user = described_class.create!(email: "test@example.com", name: "Existing User", oauth_avatar_url: "https://old.com/image.jpg")

        expect(Panda::Core::AttachAvatarService).to receive(:call).with(
          user: user,
          avatar_url: "https://example.com/image.jpg"
        )

        described_class.find_or_create_from_auth_hash(auth_hash)
      end

      it "does not call AttachAvatarService for existing users with same avatar URL and attached avatar" do
        # Create user with the oauth_avatar_url already set
        described_class.create!(email: "test@example.com", name: "Existing User", oauth_avatar_url: "https://example.com/image.jpg")

        # Stub avatar.attached? to return true since Active Storage attachments
        # don't persist properly in transactional tests
        allow_any_instance_of(described_class).to receive_message_chain(:avatar, :attached?).and_return(true)

        # Now when we call find_or_create_from_auth_hash with the same avatar URL,
        # it should NOT call the service because:
        # 1. oauth_avatar_url matches the auth_hash avatar URL
        # 2. avatar.attached? returns true
        expect(Panda::Core::AttachAvatarService).not_to receive(:call)

        described_class.find_or_create_from_auth_hash(auth_hash)
      end
    end
  end

  describe "#avatar_url" do
    let(:user) { described_class.create!(email: "test@example.com", name: "Test User") }

    context "when avatar is attached" do
      before do
        user.avatar.attach(io: File.open(Panda::Core::Engine.root.join("spec", "fixtures", "files", "test_image.jpg")), filename: "test.jpg", content_type: "image/jpeg")
      end

      it "returns the Active Storage blob path" do
        expect(user.avatar_url).to include("/rails/active_storage/blobs/")
      end
    end

    context "when avatar is not attached but image_url is present" do
      before do
        user.update_column(:image_url, "https://example.com/image.jpg")
      end

      it "returns the OAuth provider image URL" do
        expect(user.avatar_url).to eq("https://example.com/image.jpg")
      end
    end

    context "when neither avatar nor image_url is present" do
      it "returns nil" do
        expect(user.avatar_url).to be_nil
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
