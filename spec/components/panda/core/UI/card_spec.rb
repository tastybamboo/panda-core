# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::UI::Card do
  let(:output) { Capybara.string(component.call) }

  describe "initialization and property access" do
    it "accepts padding property without NameError" do
      component = described_class.new(padding: :large)
      expect(component).to be_a(described_class)
    end

    it "accepts elevation property without NameError" do
      component = described_class.new(elevation: :high)
      expect(component).to be_a(described_class)
    end

    it "accepts border property without NameError" do
      component = described_class.new(border: false)
      expect(component).to be_a(described_class)
    end

    it "has default values for properties" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering with different padding" do
    it "renders with default medium padding" do
      component = described_class.new { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("p-6")
    end

    it "renders with small padding" do
      component = described_class.new(padding: :small) { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("p-4")
    end

    it "renders with large padding" do
      component = described_class.new(padding: :large) { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("p-8")
    end

    it "renders with no padding" do
      component = described_class.new(padding: :none) { "Content" }
      output = Capybara.string(component.call)

      html = output.native.to_html
      # Should not have p-* padding classes
      expect(html).not_to match(/\sp-[0-9]/)
    end
  end

  describe "rendering with different elevation" do
    it "renders with default low elevation" do
      component = described_class.new { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("shadow-sm")
    end

    it "renders with medium elevation" do
      component = described_class.new(elevation: :medium) { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("shadow-md")
    end

    it "renders with high elevation" do
      component = described_class.new(elevation: :high) { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("shadow-lg")
    end

    it "renders with no elevation" do
      component = described_class.new(elevation: :none) { "Content" }
      output = Capybara.string(component.call)

      html = output.native.to_html
      expect(html).not_to match(/shadow-(sm|md|lg)/)
    end
  end

  describe "rendering with border" do
    it "renders with border by default" do
      component = described_class.new { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("border")
    end

    it "renders without border when border: false" do
      component = described_class.new(border: false) { "Content" }
      output = Capybara.string(component.call)

      html = output.native.to_html
      expect(html).not_to match(/border\s+border-gray-200/)
    end
  end

  describe "rendering base classes" do
    it "always includes bg-white" do
      component = described_class.new { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-white")
    end

    it "always includes rounded-lg" do
      component = described_class.new { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("rounded-lg")
    end

    it "always includes overflow-hidden" do
      component = described_class.new { "Content" }
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("overflow-hidden")
    end
  end

  end
end
