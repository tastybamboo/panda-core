# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::EmptyStateComponent, type: :component do
  describe "rendering" do
    it "renders a title" do
      component = described_class.new(title: "No records found")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h3", text: "No records found")
    end

    it "renders with an optional description" do
      component = described_class.new(title: "No records", description: "Try adding one.")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("h3", text: "No records")
      expect(output).to have_css("p", text: "Try adding one.")
    end

    it "does not render a description when none is provided" do
      component = described_class.new(title: "Empty")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_no_css("p")
    end

    it "renders with an optional icon" do
      component = described_class.new(title: "No items", icon: "fa-solid fa-box-open")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("i.fa-solid.fa-box-open")
    end

    it "renders block content" do
      component = described_class.new(title: "No items")
      output = Capybara.string(render_inline(component) { "<a href='/new'>Add one</a>".html_safe }.to_html)

      expect(output).to have_link("Add one", href: "/new")
    end
  end
end
