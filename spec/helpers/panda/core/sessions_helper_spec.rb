# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::SessionsHelper, type: :helper do
  describe "#oauth_provider_icon" do
    context "with built-in provider mappings" do
      it "returns 'google' for google_oauth2" do
        expect(helper.oauth_provider_icon(:google_oauth2)).to eq("google")
      end

      it "returns 'microsoft' for microsoft_graph" do
        expect(helper.oauth_provider_icon(:microsoft_graph)).to eq("microsoft")
      end

      it "returns 'github' for github" do
        expect(helper.oauth_provider_icon(:github)).to eq("github")
      end
    end

    context "with custom icon in provider config" do
      before do
        allow(Panda::Core.configuration).to receive(:authentication_providers).and_return(
          custom_provider: {
            icon: "building",
            name: "Custom SSO"
          }
        )
      end

      it "returns the custom icon from config" do
        expect(helper.oauth_provider_icon(:custom_provider)).to eq("building")
      end
    end

    context "with explicit icon override for built-in provider" do
      before do
        allow(Panda::Core.configuration).to receive(:authentication_providers).and_return(
          google_oauth2: {
            icon: "custom-google",
            name: "Google"
          }
        )
      end

      it "returns the overridden icon from config" do
        expect(helper.oauth_provider_icon(:google_oauth2)).to eq("custom-google")
      end
    end

    context "with unknown provider and no config" do
      before do
        allow(Panda::Core.configuration).to receive(:authentication_providers).and_return({})
      end

      it "returns the provider name as a fallback" do
        expect(helper.oauth_provider_icon(:unknown_provider)).to eq("unknown_provider")
      end
    end

    context "with string provider names" do
      it "handles string provider names" do
        expect(helper.oauth_provider_icon("google_oauth2")).to eq("google")
      end
    end
  end
end
