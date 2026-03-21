# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::DropdownButtonComponent, type: :component do
  describe "rendering" do
    it "renders a button with default text" do
      output = Capybara.string(render_inline(described_class.new).to_html)

      expect(output).to have_button("Options")
    end

    it "renders with custom text" do
      output = Capybara.string(render_inline(described_class.new(text: "View Board")).to_html)

      expect(output).to have_button("View Board")
    end

    it "renders a chevron-down icon in the button" do
      output = Capybara.string(render_inline(described_class.new(text: "View Board")).to_html)

      expect(output).to have_css("button i.fa-chevron-down")
    end

    it "renders with secondary action styling by default" do
      output = Capybara.string(render_inline(described_class.new).to_html)

      expect(output).to have_css("button.bg-white.border-gray-200")
    end

    it "renders with primary action styling" do
      output = Capybara.string(render_inline(described_class.new(action: :add)).to_html)

      expect(output).to have_css("button.bg-primary-500")
    end

    it "renders with custom icon" do
      output = Capybara.string(render_inline(described_class.new(icon: "table-columns")).to_html)

      expect(output).to have_css("button i.fa-table-columns")
    end

    it "renders dropdown menu items" do
      component = described_class.new(text: "View Board") do |db|
        db.with_item(label: "Fundraising", href: "/boards/1")
        db.with_item(label: "Events", href: "/boards/2")
      end
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_link("Fundraising", href: "/boards/1")
      expect(output).to have_link("Events", href: "/boards/2")
    end

    it "uses the dropdown Stimulus controller" do
      output = Capybara.string(render_inline(described_class.new).to_html)

      expect(output).to have_css("[data-controller='dropdown']")
    end

    it "renders the menu as hidden by default" do
      output = Capybara.string(render_inline(described_class.new).to_html)

      expect(output).to have_css("[data-dropdown-target='menu'].hidden")
    end

    it "renders items with menuitem role" do
      component = described_class.new do |db|
        db.with_item(label: "Edit", href: "/edit")
      end
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("a[role='menuitem']", text: "Edit")
    end
  end
end
