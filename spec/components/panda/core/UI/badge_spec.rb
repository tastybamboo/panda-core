# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::UI::Badge do
  let(:output) { Capybara.string(component.call) }

  describe "initialization and property access" do
    it "accepts text property without NameError" do
      component = described_class.new(text: "New")
      expect(component).to be_a(described_class)
    end

    it "accepts variant property without NameError" do
      component = described_class.new(text: "Active", variant: :success)
      expect(component).to be_a(described_class)
    end

    it "accepts size property without NameError" do
      component = described_class.new(text: "Badge", size: :small)
      expect(component).to be_a(described_class)
    end

    it "accepts removable property without NameError" do
      component = described_class.new(text: "Tag", removable: true)
      expect(component).to be_a(described_class)
    end

    it "accepts rounded property without NameError" do
      component = described_class.new(text: "Pill", rounded: true)
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering with different variants" do
    it "renders default variant" do
      component = described_class.new(text: "Badge")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-gray-50")
      expect(html).to include("text-gray-600")
    end

    it "renders primary variant" do
      component = described_class.new(text: "Primary", variant: :primary)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-blue-50")
      expect(html).to include("text-blue-700")
    end

    it "renders success variant" do
      component = described_class.new(text: "Success", variant: :success)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-green-50")
      expect(html).to include("text-green-700")
    end

    it "renders warning variant" do
      component = described_class.new(text: "Warning", variant: :warning)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-yellow-50")
      expect(html).to include("text-yellow-800")
    end

    it "renders danger variant" do
      component = described_class.new(text: "Error", variant: :danger)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-red-50")
      expect(html).to include("text-red-700")
    end

    it "renders info variant" do
      component = described_class.new(text: "Info", variant: :info)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-sky-50")
      expect(html).to include("text-sky-700")
    end
  end

  describe "rendering with different sizes" do
    it "renders default medium size" do
      component = described_class.new(text: "Badge")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("text-sm")
      expect(html).to include("px-2")
      expect(html).to include("py-0")
    end

    it "renders small size" do
      component = described_class.new(text: "Small", size: :small)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("text-xs")
      expect(html).to include("px-2")
    end

    it "renders large size" do
      component = described_class.new(text: "Large", size: :large)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("text-base")
      expect(html).to include("px-3")
    end
  end

  describe "rendering with border radius" do
    it "renders with default rounded corners" do
      component = described_class.new(text: "Badge")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("rounded")
    end

    it "renders with full rounded when rounded: true" do
      component = described_class.new(text: "Pill", rounded: true)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("rounded-full")
    end
  end

  describe "rendering base classes" do
    it "always includes inline-flex" do
      component = described_class.new(text: "Badge")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("inline-flex")
    end

    it "always includes items-center" do
      component = described_class.new(text: "Badge")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("items-center")
    end

    it "always includes font-medium" do
      component = described_class.new(text: "Badge")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("font-medium")
    end

    it "includes ring styling" do
      component = described_class.new(text: "Badge")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("ring")
    end
  end

  describe "text content" do
    it "renders the provided text" do
      component = described_class.new(text: "Custom Text")
      output = Capybara.string(component.call)

      expect(output).to have_text("Custom Text")
    end
  end

  describe "removable? method" do
    it "returns true when removable is true" do
      component = described_class.new(text: "Removable", removable: true)
      expect(component.removable?).to be true
    end

    it "returns false when removable is false" do
      component = described_class.new(text: "Badge", removable: false)
      expect(component.removable?).to be false
    end

    it "returns false by default" do
      component = described_class.new(text: "Badge")
      expect(component.removable?).to be false
    end
  end
end
