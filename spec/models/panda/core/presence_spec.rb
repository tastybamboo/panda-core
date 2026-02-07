require "rails_helper"

RSpec.describe Panda::Core::Presence, type: :model do
  let(:user) { Panda::Core::User.create!(name: "Test User", email: "test@example.com") }
  # Use User as the presenceable resource — any ActiveRecord model works with polymorphic
  let(:resource) { Panda::Core::User.create!(name: "Resource User", email: "resource@example.com") }

  describe "validations" do
    it "requires last_seen_at" do
      presence = described_class.new(presenceable: resource, user: user, last_seen_at: nil)
      expect(presence).not_to be_valid
      expect(presence.errors[:last_seen_at]).to include("can't be blank")
    end

    it "is valid with all required attributes" do
      presence = described_class.new(presenceable: resource, user: user, last_seen_at: Time.current)
      expect(presence).to be_valid
    end

    it "enforces unique presenceable + user constraint" do
      described_class.create!(presenceable: resource, user: user, last_seen_at: Time.current)
      duplicate = described_class.new(presenceable: resource, user: user, last_seen_at: Time.current)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "associations" do
    it "belongs to a presenceable (polymorphic)" do
      presence = described_class.new(presenceable: resource, user: user, last_seen_at: Time.current)
      expect(presence.presenceable).to eq(resource)
      expect(presence.presenceable_type).to eq("Panda::Core::User")
    end

    it "belongs to a user" do
      presence = described_class.new(presenceable: resource, user: user, last_seen_at: Time.current)
      expect(presence.user).to eq(user)
    end
  end

  describe "scopes" do
    let(:other_user) { Panda::Core::User.create!(name: "Other User", email: "other@example.com") }
    let!(:active_presence) { described_class.create!(presenceable: resource, user: user, last_seen_at: 5.seconds.ago) }
    let!(:stale_presence) { described_class.create!(presenceable: resource, user: other_user, last_seen_at: 60.seconds.ago) }

    describe ".active" do
      it "returns presences within the TTL" do
        expect(described_class.active(30.seconds)).to include(active_presence)
        expect(described_class.active(30.seconds)).not_to include(stale_presence)
      end
    end

    describe ".stale" do
      it "returns presences older than the TTL" do
        expect(described_class.stale(30.seconds)).to include(stale_presence)
        expect(described_class.stale(30.seconds)).not_to include(active_presence)
      end
    end

    describe ".for_resource" do
      let(:other_resource) { Panda::Core::User.create!(name: "Another Resource", email: "another@example.com") }
      let!(:other_resource_presence) { described_class.create!(presenceable: other_resource, user: user, last_seen_at: Time.current) }

      it "returns only presences for the given resource" do
        results = described_class.for_resource(resource)
        expect(results).to include(active_presence, stale_presence)
        expect(results).not_to include(other_resource_presence)
      end
    end
  end
end
