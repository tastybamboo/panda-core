# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::AuthenticationTestHelpers do
  let(:helper_host_class) do
    Class.new do
      include Panda::Core::AuthenticationTestHelpers
    end
  end

  let(:helper_host) { helper_host_class.new }

  describe "#create_admin_user" do
    it "restores the fixed admin user to an enabled admin state" do
      user = helper_host.create_admin_user
      user.update!(admin: false, enabled: false, email: "changed-admin@example.com", name: "Changed Admin")

      restored_user = helper_host.create_admin_user

      expect(restored_user.id).to eq(user.id)
      expect(restored_user.reload.admin?).to be true
      expect(restored_user.enabled?).to be true
      expect(restored_user.email).to eq("admin@example.com")
      expect(restored_user.name).to eq("Admin User")
    end
  end

  describe "#create_regular_user" do
    it "restores the fixed regular user to an enabled non-admin state" do
      user = helper_host.create_regular_user
      user.update!(admin: true, enabled: false, email: "changed-user@example.com", name: "Changed User")

      restored_user = helper_host.create_regular_user

      expect(restored_user.id).to eq(user.id)
      expect(restored_user.reload.admin?).to be false
      expect(restored_user.enabled?).to be true
      expect(restored_user.email).to eq("user@example.com")
      expect(restored_user.name).to eq("Regular User")
    end
  end
end
