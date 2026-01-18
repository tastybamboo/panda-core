# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::ContainerComponent, type: :component do
  describe "rendering" do
    it "renders a container with main content" do
      render_inline(described_class.new) { "Main content" }
      
      expect(page).to have_css("main.overflow-auto.flex-1")
      expect(page).to have_text("Main content")
    end

    it "renders with heading slot" do
      component = described_class.new
      component.with_heading(text: "Dashboard")
      component.with_body { "Page content" }
      render_inline(component)

      expect(page).to have_css("h2", text: "Dashboard")
      expect(page).to have_text("Page content")
    end

    it "renders with tab bar slot" do
      component = described_class.new
      component.with_tab_bar(tabs: [
        {name: "All", url: "/posts", current: true},
        {name: "Published", url: "/posts?status=published"}
      ])
      component.with_body { "Tab content" }
      render_inline(component)

      expect(page).to have_text("Tab content")
    end

    it "renders without optional slots" do
      render_inline(described_class.new) { "Simple content" }

      expect(page).to have_css("section.flex-auto")
      expect(page).to have_text("Simple content")
    end

    it "applies correct layout classes" do
      render_inline(described_class.new) { "Content" }

      expect(page).to have_css("main.overflow-auto.flex-1.h-full.min-h-full.max-h-full")
      expect(page).to have_css("section.flex-auto")
    end
  end
end
