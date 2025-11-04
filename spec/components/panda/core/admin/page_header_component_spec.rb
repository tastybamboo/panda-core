# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::PageHeaderComponent do
  let(:output) { Capybara.string(component.call) }

  describe "rendering" do
    it "renders title" do
      component = described_class.new(title: "Back End Developer")
      output = Capybara.string(component.call)

      expect(output).to have_css("h2", text: "Back End Developer")
    end

    it "applies correct title styling" do
      component = described_class.new(title: "Test Title")
      output = Capybara.string(component.call)

      expect(output).to have_css("h2.text-2xl\\/7.font-bold.text-gray-900")
    end

    it "renders without breadcrumbs when not provided" do
      component = described_class.new(title: "Test Title")
      output = Capybara.string(component.call)

      expect(output).not_to have_css("nav")
    end

    it "renders breadcrumbs when provided" do
      component = described_class.new(
        title: "Test Title",
        breadcrumbs: [
          {text: "Home", href: "/admin"},
          {text: "Pages", href: "/admin/pages"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_link("Home", href: "/admin")
      expect(output).to have_link("Pages", href: "/admin/pages")
    end
  end

  describe "action buttons" do
    it "renders without buttons by default" do
      component = described_class.new(title: "Test Title")
      output = Capybara.string(component.call)

      expect(output).not_to have_css("button")
      expect(output).not_to have_css("a.inline-flex.items-center")
    end

    it "renders single button" do
      component = described_class.new(title: "Test Title") do |header|
        header.button(text: "Edit", variant: :secondary, href: "/edit")
      end
      output = Capybara.string(component.call)

      expect(output).to have_link("Edit", href: "/edit")
    end

    it "renders multiple buttons" do
      component = described_class.new(title: "Test Title") do |header|
        header.button(text: "Edit", variant: :secondary, href: "/edit")
        header.button(text: "Publish", variant: :primary, href: "/publish")
      end
      output = Capybara.string(component.call)

      expect(output).to have_link("Edit", href: "/edit")
      expect(output).to have_link("Publish", href: "/publish")
    end

    it "applies margin to subsequent buttons" do
      component = described_class.new(title: "Test Title") do |header|
        header.button(text: "First", variant: :secondary, href: "/first")
        header.button(text: "Second", variant: :primary, href: "/second")
      end
      output = Capybara.string(component.call)

      # Second button should have ml-3 class
      expect(output).to have_css("a.ml-3", text: "Second")
    end

    it "renders buttons with different variants" do
      component = described_class.new(title: "Test Title") do |header|
        header.button(text: "Primary", variant: :primary, href: "/primary")
        header.button(text: "Secondary", variant: :secondary, href: "/secondary")
      end
      output = Capybara.string(component.call)

      # Check that buttons render with correct hrefs and text
      expect(output).to have_link("Primary", href: "/primary")
      expect(output).to have_link("Secondary", href: "/secondary")
    end
  end

  describe "responsive layout" do
    it "has responsive flex classes on title and actions container" do
      component = described_class.new(title: "Test Title") do |header|
        header.button(text: "Edit", variant: :secondary, href: "/edit")
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.md\\:flex.md\\:items-center.md\\:justify-between")
    end

    it "has responsive margin classes on actions" do
      component = described_class.new(title: "Test Title") do |header|
        header.button(text: "Edit", variant: :secondary, href: "/edit")
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.mt-4.flex.shrink-0.md\\:mt-0.md\\:ml-4")
    end
  end

  describe "integration with breadcrumb component" do
    it "passes show_back option to breadcrumb" do
      component = described_class.new(
        title: "Test Title",
        breadcrumbs: [
          {text: "Home", href: "/admin"}
        ],
        show_back: false
      )
      output = Capybara.string(component.call)

      expect(output).not_to have_css("nav.sm\\:hidden")
    end

    it "shows back link by default" do
      component = described_class.new(
        title: "Test Title",
        breadcrumbs: [
          {text: "Home", href: "/admin"},
          {text: "Pages", href: "/admin/pages"}
        ]
      )
      output = Capybara.string(component.call)

      expect(output).to have_css("nav.sm\\:hidden", text: "Back")
    end
  end

  describe "edge cases" do
    it "handles empty title gracefully" do
      component = described_class.new(title: "")
      output = Capybara.string(component.call)

      expect(output).to have_css("h2")
    end

    it "truncates long titles on mobile" do
      component = described_class.new(
        title: "This is a very long title that should truncate"
      )
      output = Capybara.string(component.call)

      expect(output).to have_css("h2.sm\\:truncate")
    end
  end
end
