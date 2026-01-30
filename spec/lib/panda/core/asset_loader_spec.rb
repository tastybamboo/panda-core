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

  describe ".css_url version selection" do
    before do
      allow(described_class).to receive(:use_github_assets?).and_return(false)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    end

    it "selects the highest semantic version CSS file" do
      assets_dir = Panda::Core::Engine.root.join("public", "panda-core-assets")

      css_files = %w[
        panda-core-0.11.0.css
        panda-core-0.12.2.css
        panda-core-0.12.3.css
        panda-core-0.12.5.css
        panda-core-0.13.0.css
      ].map { |f| assets_dir.join(f).to_s }

      allow(Dir).to receive(:[]).and_return(css_files)
      allow(File).to receive(:symlink?).and_return(false)

      result = described_class.css_url
      expect(result).to eq("/panda-core-assets/panda-core-0.13.0.css")
    end

    it "handles single-digit vs multi-digit version components correctly" do
      assets_dir = Panda::Core::Engine.root.join("public", "panda-core-assets")

      css_files = %w[
        panda-core-0.9.0.css
        panda-core-0.10.0.css
      ].map { |f| assets_dir.join(f).to_s }

      allow(Dir).to receive(:[]).and_return(css_files)
      allow(File).to receive(:symlink?).and_return(false)

      result = described_class.css_url
      expect(result).to eq("/panda-core-assets/panda-core-0.10.0.css")
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
