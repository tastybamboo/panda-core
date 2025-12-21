# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::UI::Button do
  let(:output) { Capybara.string(component.call) }

  describe "rendering as button" do
    it "renders a button element by default" do
      component = described_class.new(text: "Click Me")
      output = Capybara.string(component.call)

      expect(output).to have_button("Click Me")
    end

    it "applies default button type" do
      component = described_class.new(text: "Click Me")
      output = Capybara.string(component.call)

      expect(output).to have_css('button[type="button"]')
    end

    it "applies custom button type" do
      component = described_class.new(text: "Submit", type: "submit")
      output = Capybara.string(component.call)

      expect(output).to have_css('button[type="submit"]')
    end

    it "handles disabled state" do
      component = described_class.new(text: "Disabled", disabled: true)
      output = Capybara.string(component.call)

      expect(output).to have_css("button[disabled]")
      expect(output).to have_css("button.disabled\\:opacity-50")
    end
  end

  describe "rendering as link" do
    it "renders an anchor element when href is provided" do
      component = described_class.new(text: "Go to Page", href: "/admin/page")
      output = Capybara.string(component.call)

      expect(output).to have_link("Go to Page", href: "/admin/page")
      expect(output).not_to have_button
    end

    it "applies link styling with primary variant" do
      component = described_class.new(
        text: "Primary Link",
        variant: :primary,
        href: "/admin"
      )
      output = Capybara.string(component.call)

      expect(output).to have_css("a.bg-primary-500")
    end

    it "applies link styling with secondary variant" do
      component = described_class.new(
        text: "Secondary Link",
        variant: :secondary,
        href: "/admin"
      )
      output = Capybara.string(component.call)

      expect(output).to have_css("a.bg-white.text-gray-900")
    end
  end

  describe "variants" do
    it "applies primary variant styling" do
      component = described_class.new(text: "Primary", variant: :primary)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.bg-primary-500.text-white")
    end

    it "applies secondary variant styling" do
      component = described_class.new(text: "Secondary", variant: :secondary)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.bg-white.text-gray-900")
    end

    it "applies success variant styling" do
      component = described_class.new(text: "Success", variant: :success)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.bg-success-600.text-white")
    end

    it "applies danger variant styling" do
      component = described_class.new(text: "Danger", variant: :danger)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.bg-error-600.text-white")
    end

    it "applies ghost variant styling" do
      component = described_class.new(text: "Ghost", variant: :ghost)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.bg-transparent.text-gray-700")
    end

    it "applies default variant styling" do
      component = described_class.new(text: "Default", variant: :default)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.bg-gray-700.text-white")
    end
  end

  describe "sizes" do
    it "applies small size classes" do
      component = described_class.new(text: "Small", size: :small)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.px-2\\.5.py-1\\.5.text-sm")
    end

    it "applies medium size classes (default)" do
      component = described_class.new(text: "Medium", size: :medium)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.px-3.py-2.text-sm")
    end

    it "applies large size classes" do
      component = described_class.new(text: "Large", size: :large)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.px-3\\.5.py-2\\.5.text-lg")
    end
  end

  describe "styling" do
    it "applies base button classes" do
      component = described_class.new(text: "Button")
      output = Capybara.string(component.call)

      expect(output).to have_css("button.inline-flex.items-center.rounded-md.font-semibold")
    end

    it "includes shadow and hover effects for primary" do
      component = described_class.new(text: "Primary", variant: :primary)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.shadow-xs.hover\\:bg-primary-600")
    end

    it "includes ring styles for secondary" do
      component = described_class.new(text: "Secondary", variant: :secondary)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.inset-ring.inset-ring-gray-300")
    end

    it "includes dark mode classes" do
      component = described_class.new(text: "Primary", variant: :primary)
      output = Capybara.string(component.call)

      expect(output).to have_css("button.dark\\:bg-primary-400.dark\\:hover\\:bg-primary-500")
    end
  end

  describe "custom attributes" do
    it "merges custom CSS classes" do
      component = described_class.new(
        text: "Custom",
        variant: :primary,
        class: "mt-4"
      )
      output = Capybara.string(component.call)

      expect(output).to have_css("button.mt-4")
    end

    it "supports data attributes" do
      component = described_class.new(
        text: "Turbo",
        variant: :danger,
        data: {turbo_method: :delete, turbo_confirm: "Are you sure?"}
      )
      output = Capybara.string(component.call)

      expect(output).to have_css('button[data-turbo-method="delete"]')
      expect(output).to have_css('button[data-turbo-confirm="Are you sure?"]')
    end
  end
end
