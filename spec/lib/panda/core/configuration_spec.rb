require "rails_helper"

RSpec.describe Panda::Core do
  describe "configuration" do
    let(:config) { described_class.configuration }

    before(:each) do
      described_class.reset_configuration!
    end

    it "has default values" do
      expect(config.session_token_cookie).to eq(:panda_session)
      expect(config.user_class).to eq("Panda::Core::User")
      expect(config.user_identity_class).to eq("Panda::Core::UserIdentity")
    end

    it "allows setting configuration values" do
      described_class.configure do |config|
        config.session_token_cookie = :custom_session
        config.user_class = "CustomUser"
        config.user_identity_class = "CustomUserIdentity"
      end

      expect(config.session_token_cookie).to eq(:custom_session)
      expect(config.user_class).to eq("CustomUser")
      expect(config.user_identity_class).to eq("CustomUserIdentity")

      # Reset configuration
      described_class.reset_configuration!
    end
  end
end
