# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TabBarComponent do
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
      output = Capybara.string(component.call)

      expect(output).to have_link("All Posts", href: "/posts")
      expect(output).to have_link("Published", href: "/posts?status=published")
      expect(output).to have_link("Drafts", href: "/posts?status=draft")
    end

    it "highlights current tab" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(component.call)

      expect(output).to have_css("a.border-panda-dark.text-panda-dark", text: "All Posts")
    end

    it "renders mobile select" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(component.call)

      expect(output).to have_css("select#tabs")
      expect(output).to have_css("option", text: "All Posts")
    end

    it "renders desktop tabs" do
      component = described_class.new(tabs: tabs)
      output = Capybara.string(component.call)

      expect(output).to have_css("nav[aria-label='Tabs']")
    end

    it "handles empty tabs array" do
      component = described_class.new(tabs: [])
      output = Capybara.string(component.call)

      expect(output).to have_css("div.mt-3")
    end
  end
end
