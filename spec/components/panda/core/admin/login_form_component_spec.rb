# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::LoginFormComponent do
  describe "initialization" do
    it "accepts providers property without NameError" do
      component = described_class.new(providers: [])
      expect(component).to be_a(described_class)
    end

    it "has default empty providers" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering structure" do
    it "renders main container" do
      component = described_class.new(providers: [])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("flex flex-col justify-center")
    end

    it "renders header with title" do
      component = described_class.new(providers: [])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("h2")
    end
  end

  describe "rendering with no providers" do
    it "displays warning message when no providers configured" do
      component = described_class.new(providers: [])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("No authentication providers configured")
    end

    it "includes instruction text" do
      component = described_class.new(providers: [])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("Please configure at least one authentication provider")
    end
  end

  describe "rendering with providers" do
    it "renders oauth buttons for each provider" do
      component = described_class.new(providers: ["github"])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("<button")
      expect(html).to include("Sign in with")
    end

    it "renders multiple provider buttons" do
      component = described_class.new(providers: ["github", "google"])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html.scan("<button").count).to be >= 2
    end

    it "includes provider icons" do
      component = described_class.new(providers: ["github"])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("fa-")
    end
  end

  describe "Phlex property pattern" do
    it "uses @instance_variables for prop access" do
      source = File.read(Rails.root.join("../../app/components/panda/core/admin/login_form_component.rb"))

      expect(source).to include("@providers")
    end
  end
end
