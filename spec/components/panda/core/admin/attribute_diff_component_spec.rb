# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::AttributeDiffComponent, type: :component do
  describe "rendering" do
    it "renders changed attributes with default heading" do
      changes = {
        "title" => {old: "Old Title", new: "New Title"},
        "path" => {old: "/old", new: "/new"}
      }

      render_inline(described_class.new(changes: changes))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("Attribute Changes")
      expect(output).to have_text("Title")
      expect(output).to have_text("Old Title")
      expect(output).to have_text("New Title")
      expect(output).to have_text("Path")
      expect(output).to have_text("/old")
      expect(output).to have_text("/new")
    end

    it "renders custom heading" do
      changes = {"name" => {old: "Alice", new: "Bob"}}

      render_inline(described_class.new(changes: changes, heading: "User Changes"))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("User Changes")
    end

    it "renders change count" do
      changes = {
        "title" => {old: "Old", new: "New"},
        "path" => {old: "/a", new: "/b"},
        "status" => {old: "draft", new: "active"}
      }

      render_inline(described_class.new(changes: changes))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("3 changed")
    end

    it "shows (empty) for nil values" do
      changes = {
        "seo_title" => {old: nil, new: "My SEO Title"}
      }

      render_inline(described_class.new(changes: changes))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("(empty)")
      expect(output).to have_text("My SEO Title")
    end

    it "does not render when changes are empty" do
      render_inline(described_class.new(changes: {}))

      expect(rendered_content).to be_empty
    end
  end
end
