# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::ContainerComponent do
  describe "rendering" do
    it "renders a container with main content" do
      component = described_class.new do
        "Main content"
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("main.overflow-auto.flex-1")
      expect(output).to have_text("Main content")
    end

    it "renders with heading slot" do
      component = described_class.new do |container|
        container.heading(text: "Dashboard")
        container.content { "Page content" }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("h2", text: "Dashboard")
      expect(output).to have_text("Page content")
    end

    it "renders heading with button" do
      component = described_class.new do |container|
        container.heading(text: "Pages") do |heading|
          heading.button(text: "Add Page", href: "/pages/new")
        end
        container.content { "Pages list" }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("h2", text: "Pages")
      expect(output).to have_link("Add Page", href: "/pages/new")
    end

    it "renders with tab bar slot" do
      component = described_class.new do |container|
        container.tab_bar(tabs: [
          {name: "All", url: "/posts", current: true},
          {name: "Published", url: "/posts?status=published"}
        ])
        container.content { "Tab content" }
      end
      output = Capybara.string(component.call)

      expect(output).to have_text("Tab content")
    end

    it "renders without optional slots" do
      component = described_class.new do
        "Simple content"
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("section.flex-auto")
      expect(output).to have_text("Simple content")
    end

    it "applies correct layout classes" do
      component = described_class.new { "Content" }
      output = Capybara.string(component.call)

      expect(output).to have_css("main.overflow-auto.flex-1.h-full.min-h-full.max-h-full")
      expect(output).to have_css("section.flex-auto")
    end
  end
end
