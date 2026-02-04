require "rails_helper"

RSpec.describe Panda::Core::UserSession, type: :model do
  let(:user) { Panda::Core::User.create!(name: "Test User", email: "test@example.com") }
  let(:admin) { Panda::Core::User.create!(name: "Admin User", email: "admin@example.com", admin: true) }

  describe "associations" do
    it { should belong_to(:user).class_name("Panda::Core::User") }
    it { should belong_to(:revoked_by).class_name("Panda::Core::User").optional }
  end

  describe "validations" do
    subject { described_class.new(user: user, session_id: "abc123") }

    it { should validate_presence_of(:session_id) }
    it { should validate_uniqueness_of(:session_id) }
  end

  describe "#revoke!" do
    let!(:user_session) do
      described_class.create!(
        user: user,
        session_id: "session-123",
        active: true,
        last_active_at: Time.current
      )
    end

    it "marks the session as inactive" do
      user_session.revoke!(admin: admin)
      expect(user_session.reload.active).to be false
    end

    it "records the revocation time" do
      user_session.revoke!(admin: admin)
      expect(user_session.reload.revoked_at).to be_present
    end

    it "records who revoked the session" do
      user_session.revoke!(admin: admin)
      expect(user_session.reload.revoked_by).to eq(admin)
    end
  end

  describe "#touch_activity!" do
    let!(:user_session) do
      described_class.create!(
        user: user,
        session_id: "session-456",
        active: true,
        last_active_at: 1.hour.ago
      )
    end

    it "updates last_active_at" do
      expect {
        user_session.touch_activity!
      }.to change { user_session.reload.last_active_at }
    end
  end

  describe "scopes" do
    let!(:active_session) do
      described_class.create!(
        user: user,
        session_id: "active-1",
        active: true,
        last_active_at: Time.current
      )
    end

    let!(:revoked_session) do
      described_class.create!(
        user: user,
        session_id: "revoked-1",
        active: false,
        revoked_at: 1.hour.ago,
        revoked_by: admin,
        last_active_at: 2.hours.ago
      )
    end

    describe ".active_sessions" do
      it "returns only active, non-revoked sessions" do
        expect(described_class.active_sessions).to include(active_session)
        expect(described_class.active_sessions).not_to include(revoked_session)
      end
    end

    describe ".for_user" do
      let(:other_user) { Panda::Core::User.create!(name: "Other", email: "other@example.com") }
      let!(:other_session) do
        described_class.create!(user: other_user, session_id: "other-1", active: true, last_active_at: Time.current)
      end

      it "returns only sessions for the given user" do
        expect(described_class.for_user(user)).to include(active_session, revoked_session)
        expect(described_class.for_user(user)).not_to include(other_session)
      end
    end

    describe ".recent" do
      it "orders by last_active_at desc" do
        sessions = described_class.recent
        expect(sessions.first).to eq(active_session)
      end
    end
  end
end
