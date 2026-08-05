# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Engine::OmniauthConfig do
  let(:dummy_class) do
    Class.new do
      include Panda::Core::Engine::OmniauthConfig
    end
  end

  let(:instance) { dummy_class.new }

  describe "PROVIDER_REGISTRY alias resolution" do
    it "maps google to google_oauth2" do
      symbol = described_class::PROVIDER_REGISTRY["google"]
      expect(symbol).to eq(:google_oauth2)
    end

    it "maps gmail alias to google_oauth2" do
      expect(described_class::PROVIDER_REGISTRY["gmail"]).to eq(:google_oauth2)
    end

    it "maps microsoft to microsoft_graph" do
      expect(described_class::PROVIDER_REGISTRY["microsoft"]).to eq(:microsoft_graph)
    end

    it "maps gh to github" do
      expect(described_class::PROVIDER_REGISTRY["gh"]).to eq(:github)
    end

    it "maps apple to apple" do
      expect(described_class::PROVIDER_REGISTRY["apple"]).to eq(:apple)
    end
  end

  describe ".credentials_configured?" do
    it "requires client_id and client_secret for standard OAuth providers" do
      expect(described_class.credentials_configured?(:google_oauth2, {
        client_id: "CID",
        client_secret: "SECRET"
      })).to be(true)

      expect(described_class.credentials_configured?(:google_oauth2, {
        client_id: "CID",
        client_secret: ""
      })).to be(false)
    end

    it "requires Apple JWT options instead of a static client_secret" do
      apple_settings = {
        client_id: "com.example.service",
        options: {
          team_id: "TEAMID",
          key_id: "KEYID",
          pem: "-----BEGIN PRIVATE KEY-----\nMII\n-----END PRIVATE KEY-----"
        }
      }

      expect(described_class.credentials_configured?(:apple, apple_settings)).to be(true)
      expect(described_class.credentials_configured?(:apple, apple_settings.merge(options: {}))).to be(false)
      expect(described_class.credentials_configured?(:apple, {
        client_id: "com.example.service",
        client_secret: "ignored"
      })).to be(false)
    end
  end

  describe "#configure_provider" do
    let(:builder) { double("OmniAuth::Builder") }

    it "configures a provider with client credentials" do
      expect(builder).to receive(:provider).with(
        :google_oauth2,
        "CID",
        "SECRET",
        {}
      )

      instance.send(:configure_provider, builder, "google", {
        client_id: "CID",
        client_secret: "SECRET"
      })
    end

    it "configures Apple with JWT options and an empty static secret" do
      pem = "-----BEGIN PRIVATE KEY-----\nMII\n-----END PRIVATE KEY-----"
      expect(builder).to receive(:provider).with(
        :apple,
        "com.example.service",
        "",
        {team_id: "TEAMID", key_id: "KEYID", pem: pem}
      )

      instance.send(:configure_provider, builder, "apple", {
        client_id: "com.example.service",
        options: {team_id: "TEAMID", key_id: "KEYID", pem: pem}
      })
    end

    it "skips Apple when JWT options are incomplete" do
      expect(builder).not_to receive(:provider)
      expect(Rails.logger).to receive(:info).with(/Skipping OmniAuth provider/)

      instance.send(:configure_provider, builder, "apple", {
        client_id: "com.example.service",
        client_secret: "unused"
      })
    end

    it "supports path_name override" do
      expect(builder).to receive(:provider).with(
        :github,
        "A",
        "B",
        {name: "enterprise"}
      )

      instance.send(:configure_provider, builder, "github", {
        client_id: "A",
        client_secret: "B",
        path_name: "enterprise"
      })
    end

    it "warns on unknown provider" do
      expect(Rails.logger).to receive(:warn).with(/Unknown OmniAuth provider/)
      instance.send(:configure_provider, builder, "unknown", {})
    end

    it "skips developer provider outside development" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      expect(builder).not_to receive(:provider)
      instance.send(:configure_provider, builder, "developer", {})
    end
  end

  describe "#load_yaml_provider_overrides!" do
    let(:yaml_path) { Panda::Core::Engine.root.join("config/providers.yml") }
    let!(:original_providers) { Panda::Core.config.authentication_providers.dup }

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(YAML).to receive(:load_file).and_return({
        "providers" => {
          "google" => {"client_id" => "X", "client_secret" => "Y"}
        }
      })
    end

    after do
      Panda::Core.config.authentication_providers = original_providers
    end

    it "merges YAML provider overrides" do
      Panda::Core.config.authentication_providers["google"] = {}

      instance.send(:load_yaml_provider_overrides!)

      expect(Panda::Core.config.authentication_providers["google"]["client_id"]).to eq("X")
    end
  end
end
