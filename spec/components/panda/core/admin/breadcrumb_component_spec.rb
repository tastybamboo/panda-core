# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::BreadcrumbComponent do
  let(:output) { Capybara.string(component.call) }

  describe "rendering" do
    it "renders breadcrumb items" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"},
          {text: "Pages", href: "/admin/pages"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_link("Home", href: "/admin")
      expect(output).to have_link("Pages", href: "/admin/pages")
    end

    it "renders back link on mobile" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"},
          {text: "Pages", href: "/admin/pages"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_css("nav.sm\\:hidden", text: "Back")
    end

    it "hides back link when show_back is false" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"}
        ],
        show_back: false
      )
      output = Capybara.string(component.call)

      expect(output).not_to have_css("nav.sm\\:hidden")
    end

    it "renders chevron separators between items" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"},
          {text: "Pages", href: "/admin/pages"},
          {text: "Edit", href: "/admin/pages/1/edit"}
        ]
      )
      output = Capybara.string(component.call)

      # Should have 2 chevron icons (one less than number of items)
      expect(output.all("svg").count).to be >= 2
    end

    it "marks last item with aria-current" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"},
          {text: "Current Page", href: "/admin/current"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_css('a[aria-current="page"]', text: "Current Page")
    end

    it "applies correct styling classes" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_css("a.text-gray-500.hover\\:text-gray-700")
    end

    it "renders accessible ARIA labels" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_css('nav[aria-label="Breadcrumb"]')
    end
  end

  describe "edge cases" do
    it "handles empty items array" do
      component = described_class.new(items: [])
      output = Capybara.string(component.call)

      expect(output.text.strip).to eq("")
    end

    it "handles single item" do
      component = described_class.new(
        items: [
          {text: "Home", href: "/admin"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_link("Home", href: "/admin")
    end
  end
end
