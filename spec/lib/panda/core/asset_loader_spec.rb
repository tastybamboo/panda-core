# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::AssetLoader do
  describe ".use_github_assets?" do
    before do
      # Mock in_test_environment? to avoid always returning false in tests
      allow(described_class).to receive(:in_test_environment?).and_return(false)
    end

    context "in test environment" do
      it "never uses GitHub assets (due to Rails.env.test? check)" do
        expect(described_class.use_github_assets?).to be false
      end
    end

    context "in production environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end

      context "when compiled assets are available locally" do
        before do
          allow(described_class).to receive(:compiled_assets_available?).and_return(true)
        end

        it "uses local assets instead of GitHub" do
          expect(described_class.use_github_assets?).to be false
        end

        it "does not try to load from GitHub" do
          expect(described_class.use_github_assets?).to be false
        end
      end

      context "when compiled assets are NOT available locally" do
        before do
          allow(described_class).to receive(:compiled_assets_available?).and_return(false)
        end

        it "does not use GitHub assets by default" do
          expect(described_class.use_github_assets?).to be false
        end

        context "when explicitly enabled via env var" do
          before do
            allow(ENV).to receive(:[]).and_call_original
            allow(ENV).to receive(:[]).with("PANDA_CORE_USE_GITHUB_ASSETS").and_return("true")
          end

          it "uses GitHub assets" do
            expect(described_class.use_github_assets?).to be true
          end
        end
      end
    end

    context "in development environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      context "when development assets are available" do
        before do
          allow(described_class).to receive(:development_assets_available?).and_return(true)
        end

        it "does not use GitHub assets" do
          expect(described_class.use_github_assets?).to be false
        end
      end

      context "when development assets are NOT available" do
        before do
          allow(described_class).to receive(:development_assets_available?).and_return(false)
        end

        it "uses GitHub assets as fallback" do
          expect(described_class.use_github_assets?).to be true
        end
      end

      context "when explicitly enabled via env var" do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with("PANDA_CORE_USE_GITHUB_ASSETS").and_return("true")
        end

        it "uses GitHub assets" do
          expect(described_class.use_github_assets?).to be true
        end
      end
    end
  end

  describe ".asset_tags" do
    context "when using local assets" do
      before do
        allow(described_class).to receive(:use_github_assets?).and_return(false)
      end

      it "uses development asset tags" do
        expect(described_class).to receive(:development_asset_tags)
        described_class.asset_tags
      end
    end

    context "when using GitHub assets" do
      before do
        allow(described_class).to receive(:use_github_assets?).and_return(true)
      end

      it "uses GitHub asset tags" do
        expect(described_class).to receive(:github_asset_tags)
        described_class.asset_tags
      end
    end
  end
end
