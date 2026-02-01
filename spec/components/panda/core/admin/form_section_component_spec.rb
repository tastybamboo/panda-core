# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FormSectionComponent, type: :component do
  describe "rendering" do
    it "renders with title" do
      component = described_class.new(title: "SEO Settings")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("SEO Settings")
    end

    it "renders with description when provided" do
      component = described_class.new(title: "Settings", description: "Configure your preferences")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Configure your preferences")
    end

    it "does not render description when not provided" do
      component = described_class.new(title: "Settings")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).not_to have_css("p.text-gray-500")
    end

    it "renders icon when provided" do
      component = described_class.new(title: "Menu Items", icon: "fa-bars")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("i.fa-bars")
    end

    it "renders block content" do
      component = described_class.new(title: "Test")
      output = Capybara.string(render_inline(component) { "<p>Form content</p>".html_safe }.to_html)

      expect(output).to have_text("Form content")
    end

    it "applies border-top by default" do
      component = described_class.new(title: "Section")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.border-t")
    end

    it "does not apply border-top when border_top is false" do
      component = described_class.new(title: "Section", border_top: false)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).not_to have_css("div.border-t")
    end
  end

  describe "#heading_classes" do
    it "returns appropriate heading classes" do
      component = described_class.new(title: "Test")
      expect(component.heading_classes).to include("text-sm")
      expect(component.heading_classes).to include("font-semibold")
    end
  end

  describe "#description_classes" do
    it "returns appropriate description classes" do
      component = described_class.new(title: "Test")
      expect(component.description_classes).to include("text-xs")
      expect(component.description_classes).to include("text-slate-500")
    end
  end

  describe "#content_classes" do
    it "returns appropriate content wrapper classes" do
      component = described_class.new(title: "Test")
      expect(component.content_classes).to include("mt-4")
      expect(component.content_classes).to include("space-y-4")
    end
  end
end
