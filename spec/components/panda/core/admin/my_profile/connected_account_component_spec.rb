# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::MyProfile::ConnectedAccountComponent, type: :component do
  let(:user_struct) do
    Struct.new(:oauth_provider)
  end

  let(:connected_user) { user_struct.new("microsoft_graph") }
  let(:disconnected_user) { user_struct.new("google_oauth2") }

  describe "rendering" do
    context "when provider is connected" do
      subject(:component) { described_class.new(provider: :microsoft_graph, user: connected_user) }

      it "renders the provider name" do
        output = Capybara.string(component.call)
        expect(output).to have_css("h3", text: "Microsoft")
      end

      it "renders the provider icon" do
        output = Capybara.string(component.call)
        expect(output).to have_css("i.fa-brands.fa-microsoft")
      end

      it "shows connected status" do
        output = Capybara.string(component.call)
        expect(output).to have_css("p.text-green-600", text: "Connected")
        expect(output).to have_css("i.fa-check-circle")
      end

      it "renders disabled Connected button" do
        output = Capybara.string(component.call)
        expect(output).to have_css("button[disabled]", text: "Connected")
      end

      it "applies provider color to icon" do
        output = Capybara.string(component.call)
        expect(output).to have_css("i[style*='color: #00a4ef']")
      end
    end

    context "when provider is not connected" do
      subject(:component) { described_class.new(provider: :google_oauth2, user: connected_user) }

      it "renders the provider name" do
        output = Capybara.string(component.call)
        expect(output).to have_css("h3", text: "Google")
      end

      it "renders the provider icon" do
        output = Capybara.string(component.call)
        expect(output).to have_css("i.fa-brands.fa-google")
      end

      it "shows not connected status" do
        output = Capybara.string(component.call)
        expect(output).to have_css("p.text-gray-500", text: "Not connected")
        expect(output).not_to have_css("i.fa-check-circle")
      end

      it "renders disabled Connect button with tooltip" do
        output = Capybara.string(component.call)
        expect(output).to have_css("a[title='OAuth re-connection coming soon']", text: "Connect")
      end

      it "applies provider color to icon" do
        output = Capybara.string(component.call)
        expect(output).to have_css("i[style*='color: #4285f4']")
      end
    end

    context "with GitHub provider" do
      subject(:component) { described_class.new(provider: :github, user: connected_user) }

      it "renders GitHub branding" do
        output = Capybara.string(component.call)
        expect(output).to have_css("h3", text: "GitHub")
        expect(output).to have_css("i.fa-brands.fa-github")
        expect(output).to have_css("i[style*='color: #333']")
      end
    end
  end

  describe "structure" do
    subject(:component) { described_class.new(provider: :microsoft_graph, user: connected_user) }

    it "renders in a bordered container" do
      output = Capybara.string(component.call)
      expect(output).to have_css("div.border.border-gray-200.rounded-lg")
    end

    it "renders icon in a background container" do
      output = Capybara.string(component.call)
      expect(output).to have_css("div.bg-gray-100.rounded-lg")
    end

    it "uses flexbox layout" do
      output = Capybara.string(component.call)
      expect(output).to have_css("div.flex.items-center.justify-between")
    end
  end
end
