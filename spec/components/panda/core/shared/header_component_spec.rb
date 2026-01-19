# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Shared::HeaderComponent do
  describe "initialization" do
    it "accepts html_class property" do
      component = described_class.new(html_class: "custom-class")
      expect(component).to be_a(described_class)
    end

    it "accepts body_class property" do
      component = described_class.new(body_class: "bg-gradient")
      expect(component).to be_a(described_class)
    end

    it "has default values" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    it "renders HTML structure" do
      component = described_class.new
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("<!DOCTYPE html>")
      expect(html).to include("<html")
      expect(html).to include("<head>")
      expect(html).to include("<body")
    end

    it "includes data-theme attribute" do
      component = described_class.new
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("data-theme=")
    end

    it "includes FontAwesome stylesheet" do
      component = described_class.new
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("fontawesome-free")
    end

    it "applies custom html_class" do
      component = described_class.new(html_class: "h-full")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include('class="h-full"')
    end

    it "applies custom body_class" do
      component = described_class.new(body_class: "bg-gradient-admin")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-gradient-admin")
    end
  end
end
