require "rails_helper"

RSpec.describe Panda::Core::PresenceService do
  let(:user) { Panda::Core::User.create!(name: "Test User", email: "test@example.com") }
  let(:other_user) { Panda::Core::User.create!(name: "Other User", email: "other@example.com") }
  # Use User as the presenceable resource — any ActiveRecord model works with polymorphic
  let(:resource) { Panda::Core::User.create!(name: "Resource User", email: "resource@example.com") }

  describe ".record_presence" do
    it "creates a new presence record" do
      expect {
        described_class.record_presence(resource, user.id)
      }.to change(Panda::Core::Presence, :count).by(1)
    end

    it "returns the presence record" do
      presence = described_class.record_presence(resource, user.id)
      expect(presence).to be_a(Panda::Core::Presence)
      expect(presence.presenceable).to eq(resource)
      expect(presence.user_id).to eq(user.id)
    end

    it "updates last_seen_at on subsequent calls (upsert)" do
      described_class.record_presence(resource, user.id)
      presence = Panda::Core::Presence.find_by(
        presenceable_type: resource.class.name,
        presenceable_id: resource.id,
        user_id: user.id
      )
      presence.update_column(:last_seen_at, 10.seconds.ago)
      first_seen = presence.reload.last_seen_at

      described_class.record_presence(resource, user.id)
      second_seen = presence.reload.last_seen_at
      expect(second_seen).to be > first_seen
    end

    it "does not create duplicate rows on upsert" do
      described_class.record_presence(resource, user.id)
      expect {
        described_class.record_presence(resource, user.id)
      }.not_to change(Panda::Core::Presence, :count)
    end
  end

  describe ".remove_presence" do
    it "deletes the presence record" do
      described_class.record_presence(resource, user.id)
      expect {
        described_class.remove_presence(resource, user.id)
      }.to change(Panda::Core::Presence, :count).by(-1)
    end

    it "does not raise when no record exists" do
      expect {
        described_class.remove_presence(resource, user.id)
      }.not_to raise_error
    end

    it "does not affect other users' presences" do
      described_class.record_presence(resource, user.id)
      described_class.record_presence(resource, other_user.id)

      described_class.remove_presence(resource, user.id)

      expect(Panda::Core::Presence.where(user_id: other_user.id).count).to eq(1)
    end
  end

  describe ".current_editors" do
    it "returns active editors with user_id and user_name" do
      described_class.record_presence(resource, user.id)

      editors = described_class.current_editors(resource)
      expect(editors.length).to eq(1)
      expect(editors.first[:user_id]).to eq(user.id)
      expect(editors.first[:user_name]).to eq(user.name)
    end

    it "excludes stale presences" do
      described_class.record_presence(resource, user.id)
      Panda::Core::Presence.update_all(last_seen_at: 60.seconds.ago)

      editors = described_class.current_editors(resource)
      expect(editors).to be_empty
    end

    it "returns multiple active editors" do
      described_class.record_presence(resource, user.id)
      described_class.record_presence(resource, other_user.id)

      editors = described_class.current_editors(resource)
      expect(editors.length).to eq(2)
    end

    it "uses email as fallback when name is blank" do
      user.update!(name: "")
      described_class.record_presence(resource, user.id)

      editors = described_class.current_editors(resource)
      expect(editors.first[:user_name]).to eq(user.email)
    end
  end

  describe ".cleanup_stale!" do
    it "deletes stale presence records" do
      described_class.record_presence(resource, user.id)
      Panda::Core::Presence.update_all(last_seen_at: 60.seconds.ago)

      expect {
        described_class.cleanup_stale!
      }.to change(Panda::Core::Presence, :count).by(-1)
    end

    it "preserves active presence records" do
      described_class.record_presence(resource, user.id)

      expect {
        described_class.cleanup_stale!
      }.not_to change(Panda::Core::Presence, :count)
    end
  end
end
