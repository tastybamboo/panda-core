require "rails_helper"

RSpec.describe Panda::Core::UserActivity, type: :model do
  let(:user) { Panda::Core::User.create!(name: "Test User", email: "test@example.com") }

  describe "associations" do
    it { should belong_to(:user).class_name("Panda::Core::User") }
  end

  describe "validations" do
    it { should validate_presence_of(:action) }
  end

  describe ".log!" do
    it "creates an activity record" do
      expect {
        described_class.log!(user: user, action: "login")
      }.to change(described_class, :count).by(1)
    end

    it "records the action" do
      activity = described_class.log!(user: user, action: "login")
      expect(activity.action).to eq("login")
    end

    it "records metadata" do
      activity = described_class.log!(user: user, action: "invited_user", metadata: {invited_email: "new@example.com"})
      expect(activity.metadata).to eq({"invited_email" => "new@example.com"})
    end

    it "records request details when request is provided" do
      request = double("request", remote_ip: "127.0.0.1", user_agent: "Mozilla/5.0")
      activity = described_class.log!(user: user, action: "login", request: request)
      expect(activity.ip_address).to eq("127.0.0.1")
      expect(activity.user_agent).to eq("Mozilla/5.0")
    end

    it "records polymorphic resource" do
      target_user = Panda::Core::User.create!(name: "Target", email: "target@example.com")
      activity = described_class.log!(user: user, action: "updated_user", resource: target_user)
      expect(activity.resource_type).to eq("Panda::Core::User")
      expect(activity.resource_id).to eq(target_user.id)
    end
  end

  describe "scopes" do
    before do
      described_class.log!(user: user, action: "login")
      described_class.log!(user: user, action: "updated_user")
    end

    describe ".recent" do
      it "orders by created_at desc" do
        activities = described_class.recent
        expect(activities.first.action).to eq("updated_user")
      end
    end

    describe ".for_user" do
      let(:other_user) { Panda::Core::User.create!(name: "Other", email: "other@example.com") }

      before { described_class.log!(user: other_user, action: "login") }

      it "returns only activities for the given user" do
        expect(described_class.for_user(user).count).to eq(2)
      end
    end

    describe ".by_action" do
      it "filters by action" do
        expect(described_class.by_action("login").count).to eq(1)
      end
    end

    describe ".today" do
      it "returns activities from today" do
        expect(described_class.today.count).to eq(2)
      end
    end

    describe ".this_week" do
      it "returns activities from this week" do
        expect(described_class.this_week.count).to eq(2)
      end
    end
  end
end
