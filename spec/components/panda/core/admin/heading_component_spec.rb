# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::HeadingComponent, type: :component do
  describe "rendering" do
    it "renders a heading with text" do
      component = described_class.new(text: "Dashboard")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h2", text: "Dashboard")
    end

    it "renders level 1 heading" do
      component = described_class.new(text: "Main Title", level: 1)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h1", text: "Main Title")
      expect(output).to have_css("h1.text-2xl.font-semibold")
    end

    it "renders level 2 heading by default" do
      component = described_class.new(text: "Subtitle")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h2", text: "Subtitle")
      expect(output).to have_css("h2.text-xl.font-semibold")
    end

    it "renders level 3 heading" do
      component = described_class.new(text: "Section Title", level: 3)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h3", text: "Section Title")
      expect(output).to have_css("h3.text-lg.font-medium")
    end

    it "renders with button slot" do
      component = described_class.new(text: "Pages") do |heading|
        heading.with_button(text: "Add Page", href: "/pages/new", action: :add)
      end
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h2", text: "Pages")
      expect(output).to have_link("Add Page", href: "/pages/new")
      expect(output).to have_css("span.actions")
    end

    it "renders with multiple buttons" do
      component = described_class.new(text: "Posts") do |heading|
        heading.with_button(text: "New Post", href: "/posts/new")
        heading.with_button(text: "Import", href: "/posts/import")
      end
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_link("New Post")
      expect(output).to have_link("Import")
    end

    it "applies additional styles" do
      component = described_class.new(text: "Custom", additional_styles: "border-b pb-4")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h2.border-b.pb-4")
    end

    it "does not render an icon by default" do
      component = described_class.new(text: "Pages", level: 1)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h1", text: "Pages")
      expect(output).to have_no_css("h1 i")
    end
  end
end
