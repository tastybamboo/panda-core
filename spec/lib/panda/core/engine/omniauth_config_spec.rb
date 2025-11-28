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

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(YAML).to receive(:load_file).and_return({
        "providers" => {
          "google" => {"client_id" => "X", "client_secret" => "Y"}
        }
      })
    end

    it "merges YAML provider overrides" do
      Panda::Core.config.authentication_providers["google"] = {}

      instance.send(:load_yaml_provider_overrides!)

      expect(Panda::Core.config.authentication_providers["google"]["client_id"]).to eq("X")
    end
  end
end
