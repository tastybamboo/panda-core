# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TabBarComponent, type: :component do
  let(:tabs) do
    [
      {name: "All Posts", url: "/posts", current: true},
      {name: "Published", url: "/posts?status=published", current: false},
      {name: "Drafts", url: "/posts?status=draft", current: false}
    ]
  end

  describe "rendering" do
    it "renders tabs with navigation" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_link("All Posts", href: "/posts")
      expect(output).to have_link("Published", href: "/posts?status=published")
      expect(output).to have_link("Drafts", href: "/posts?status=draft")
    end

    it "highlights current tab" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("a.border-primary-600.text-primary-600", text: "All Posts")
    end

    it "renders mobile select" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("select#tabs")
      expect(output).to have_css("option", text: "All Posts")
    end

    it "renders desktop tabs" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("nav[aria-label='Tabs']")
    end

    it "handles empty tabs array" do
      component = described_class.new(tabs: [])
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.mt-3")
    end

    context "when a non-first tab is current" do
      let(:tabs) do
        [
          {name: "All Files", url: "/files", current: false},
          {name: "Images", url: "/files?category=images", current: true},
          {name: "Documents", url: "/files?category=docs", current: false}
        ]
      end

      it "highlights only the current tab, not the first" do
        component = described_class.new(tabs: tabs)
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_css("a.border-primary-600.text-primary-600", text: "Images")
        expect(output).to have_no_css("a.border-primary-600.text-primary-600", text: "All Files")
      end
    end

    context "when no tab is explicitly current" do
      let(:tabs) do
        [
          {name: "Tab A", url: "/a"},
          {name: "Tab B", url: "/b"}
        ]
      end

      it "defaults to highlighting the first tab" do
        component = described_class.new(tabs: tabs)
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_css("a.border-primary-600.text-primary-600", text: "Tab A")
      end
    end

    it "renders mobile select with URL values and onchange navigation" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("select#tabs[onchange]")
      expect(output).to have_css("option[value='/posts']", text: "All Posts")
      expect(output).to have_css("option[value='/posts?status=published']", text: "Published")
    end

    it "marks the current tab as selected in mobile select" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("option[selected][value='/posts']", text: "All Posts")
    end
  end
end
