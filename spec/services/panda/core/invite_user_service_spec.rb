require "rails_helper"

RSpec.describe Panda::Core::InviteUserService do
  let!(:admin) { Panda::Core::User.create!(name: "Admin User", email: "admin@example.com", admin: true) }

  describe ".call" do
    context "with valid params" do
      it "creates a new user" do
        expect {
          described_class.call(email: "invited@example.com", name: "New User", invited_by: admin)
        }.to change(Panda::Core::User, :count).by(1)
      end

      it "returns a successful result" do
        result = described_class.call(email: "invited@example.com", name: "New User", invited_by: admin)
        expect(result).to be_success
      end

      it "sets the invitation token on the user" do
        result = described_class.call(email: "invited@example.com", name: "New User", invited_by: admin)
        user = result.payload[:user]
        expect(user.invitation_token).to be_present
      end

      it "sets invitation_sent_at" do
        result = described_class.call(email: "invited@example.com", name: "New User", invited_by: admin)
        user = result.payload[:user]
        expect(user.invitation_sent_at).to be_present
      end

      it "sets the invited_by reference" do
        result = described_class.call(email: "invited@example.com", name: "New User", invited_by: admin)
        user = result.payload[:user]
        expect(user.invited_by).to eq(admin)
      end

      it "logs user activity" do
        expect {
          described_class.call(email: "invited@example.com", name: "New User", invited_by: admin)
        }.to change(Panda::Core::UserActivity, :count).by(1)
      end

      it "sets admin flag when requested" do
        result = described_class.call(email: "invited@example.com", name: "New User", invited_by: admin, admin: true)
        user = result.payload[:user]
        expect(user.admin?).to be true
      end

      it "defaults to non-admin" do
        result = described_class.call(email: "invited@example.com", name: "New User", invited_by: admin)
        user = result.payload[:user]
        expect(user.admin?).to be false
      end
    end

    context "with missing email" do
      it "returns a failure result" do
        result = described_class.call(email: "", name: "New User", invited_by: admin)
        expect(result).not_to be_success
      end

      it "includes error message" do
        result = described_class.call(email: "", name: "New User", invited_by: admin)
        expect(result.errors).to include("Email is required")
      end
    end

    context "with missing name" do
      it "returns a failure result" do
        result = described_class.call(email: "invited@example.com", name: "", invited_by: admin)
        expect(result).not_to be_success
      end

      it "includes error message" do
        result = described_class.call(email: "invited@example.com", name: "", invited_by: admin)
        expect(result.errors).to include("Name is required")
      end
    end

    context "when user already exists" do
      before { Panda::Core::User.create!(name: "Existing User", email: "existing@example.com") }

      it "returns a failure result" do
        result = described_class.call(email: "existing@example.com", name: "New User", invited_by: admin)
        expect(result).not_to be_success
      end

      it "includes error message" do
        result = described_class.call(email: "existing@example.com", name: "New User", invited_by: admin)
        expect(result.errors).to include("A user with this email already exists")
      end
    end

    context "email normalization" do
      it "downcases email" do
        result = described_class.call(email: "UPPER@EXAMPLE.COM", name: "New User", invited_by: admin)
        user = result.payload[:user]
        expect(user.email).to eq("upper@example.com")
      end

      it "strips whitespace from email" do
        result = described_class.call(email: "  spaced@example.com  ", name: "New User", invited_by: admin)
        user = result.payload[:user]
        expect(user.email).to eq("spaced@example.com")
      end
    end
  end
end
