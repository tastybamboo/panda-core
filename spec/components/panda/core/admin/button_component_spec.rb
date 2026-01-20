# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::ButtonComponent, type: :component do
  let(:output) { Capybara.string(render_inline(component).to_html) }

  describe "rendering" do
    it "renders a button with default text" do
      component = described_class.new(text: "Click Me")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_link("Click Me")
    end

    it "applies action-based styling for save action" do
      component = described_class.new(text: "Save", action: :save, href: "/save")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("a.bg-primary-500")
      expect(output).to have_css("a.text-white")
    end

    it "applies action-based styling for delete action" do
      component = described_class.new(text: "Delete", action: :delete, href: "/delete")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("a.text-error-600")
    end

    it "renders with custom link" do
      component = described_class.new(text: "Go", href: "/custom-path")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_link("Go", href: "/custom-path")
    end

    it "displays icon for add action" do
      component = described_class.new(text: "Add", action: :add, href: "/add")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("i.fa-plus")
    end

    it "applies size classes" do
      component = described_class.new(text: "Small", size: :small)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("a.text-sm")
    end
  end
end
