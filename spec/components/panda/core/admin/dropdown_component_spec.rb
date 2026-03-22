# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::DropdownComponent, type: :component do
  describe "rendering" do
    it "renders with the dropdown Stimulus controller" do
      component = described_class.new
      output = Capybara.string(render_inline(component) { |d| d.with_item(label: "Edit", href: "/edit") }.to_html)

      expect(output).to have_css('[data-controller="dropdown"]')
    end

    it "renders menu items with href" do
      component = described_class.new
      output = Capybara.string(render_inline(component) { |d|
        d.with_item(label: "Edit", href: "/edit")
        d.with_item(label: "Delete", href: "/delete")
      }.to_html)

      expect(output).to have_link("Edit", href: "/edit")
      expect(output).to have_link("Delete", href: "/delete")
    end

    it "renders menu items with role=menuitem" do
      component = described_class.new
      output = Capybara.string(render_inline(component) { |d| d.with_item(label: "Action", href: "/action") }.to_html)

      expect(output).to have_css("a[role='menuitem']", text: "Action")
    end

    it "renders a default chevron trigger when no custom trigger is given" do
      component = described_class.new
      output = Capybara.string(render_inline(component) { |d| d.with_item(label: "Option", href: "#") }.to_html)

      expect(output).to have_css("button i.fa-solid.fa-chevron-down")
    end

    it "renders a custom trigger slot" do
      component = described_class.new
      output = Capybara.string(render_inline(component) { |d|
        d.with_trigger_slot { "Custom Trigger".html_safe }
        d.with_item(label: "Option", href: "#")
      }.to_html)

      expect(output).to have_text("Custom Trigger")
      expect(output).to have_no_css("i.fa-chevron-down")
    end
  end
end
