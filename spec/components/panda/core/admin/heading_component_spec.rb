# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::HeadingComponent do
  describe "rendering" do
    it "renders a heading with text" do
      component = described_class.new(text: "Dashboard")
      output = Capybara.string(component.call)

      expect(output).to have_css("h2", text: "Dashboard")
    end

    it "renders level 1 heading" do
      component = described_class.new(text: "Main Title", level: 1)
      output = Capybara.string(component.call)

      expect(output).to have_css("h1", text: "Main Title")
      expect(output).to have_css("h1.text-2xl.font-medium")
    end

    it "renders level 2 heading by default" do
      component = described_class.new(text: "Subtitle")
      output = Capybara.string(component.call)

      expect(output).to have_css("h2", text: "Subtitle")
      expect(output).to have_css("h2.text-xl.font-medium")
    end

    it "renders level 3 heading" do
      component = described_class.new(text: "Section Title", level: 3)
      output = Capybara.string(component.call)

      expect(output).to have_css("h3", text: "Section Title")
      expect(output).to have_css("h3.text-xl.font-light")
    end

    it "renders panel heading style" do
      component = described_class.new(text: "Panel Header", level: :panel)
      output = Capybara.string(component.call)

      expect(output).to have_css("h3.text-base.font-medium.text-white", text: "Panel Header")
    end

    it "renders with button slot" do
      component = described_class.new(text: "Pages") do |heading|
        heading.button(text: "Add Page", href: "/pages/new", action: :add)
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("h2", text: "Pages")
      expect(output).to have_link("Add Page", href: "/pages/new")
      expect(output).to have_css("span.actions")
    end

    it "renders with multiple buttons" do
      component = described_class.new(text: "Posts") do |heading|
        heading.button(text: "New Post", href: "/posts/new")
        heading.button(text: "Import", href: "/posts/import")
      end
      output = Capybara.string(component.call)

      expect(output).to have_link("New Post")
      expect(output).to have_link("Import")
    end

    it "applies additional styles" do
      component = described_class.new(text: "Custom", additional_styles: "border-b pb-4")
      output = Capybara.string(component.call)

      expect(output).to have_css("h2.border-b.pb-4")
    end
  end
end
