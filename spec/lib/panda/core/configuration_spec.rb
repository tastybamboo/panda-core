require "rails_helper"

RSpec.describe Panda::Core do
  describe "configuration" do
    before do
      # Reset configuration to defaults before each test
      described_class.reset_configuration!
    end

    after do
      # Reset configuration after each test
      described_class.reset_configuration!
    end

    it "has default values" do
      config = described_class.config
      expect(config.authentication_providers).to eq({})
      expect(config.storage_provider).to eq(:active_storage)
      expect(config.cache_store).to eq(:memory_store)
      expect(config.admin_path).to eq("/admin")
      expect(config.user_class).to eq("Panda::Core::User")
    end

    it "allows setting configuration values" do
      described_class.configure do |config|
        config.user_class = "CustomUser"
        config.authentication_providers = {github: {client_id: "123"}}
        config.storage_provider = :s3
        config.cache_store = :redis_store
        config.admin_path = "/custom_admin"
      end

      config = described_class.config
      expect(config.user_class).to eq("CustomUser")
      expect(config.authentication_providers).to eq({github: {client_id: "123"}})
      expect(config.storage_provider).to eq(:s3)
      expect(config.cache_store).to eq(:redis_store)
      expect(config.admin_path).to eq("/custom_admin")
    end

    it "has hook system settings with defaults" do
      config = described_class.config
      expect(config.admin_navigation_items).to respond_to(:call)
      expect(config.admin_dashboard_widgets).to respond_to(:call)
      expect(config.user_attributes).to eq([])
      expect(config.user_associations).to eq([])
      expect(config.authorization_policy).to respond_to(:call)
    end
  end
end
