# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::CalloutComponent, type: :component do
  describe "rendering" do
    it "renders text content" do
      component = described_class.new(text: "This is a notice.")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("This is a notice.")
    end

    it "renders with a title" do
      component = described_class.new(text: "Details here.", title: "Important")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Important")
      expect(output).to have_text("Details here.")
    end

    it "renders info kind with default icon and styling" do
      component = described_class.new(text: "Info message", kind: :info)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.bg-gray-50")
      expect(output).to have_css("i.fa-circle-info")
    end

    it "renders success kind with correct icon and styling" do
      component = described_class.new(text: "Success!", kind: :success)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.bg-emerald-50")
      expect(output).to have_css("i.fa-circle-check")
    end

    it "renders warning kind with correct icon and styling" do
      component = described_class.new(text: "Warning!", kind: :warning)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.bg-amber-50")
      expect(output).to have_css("i.fa-triangle-exclamation")
    end

    it "renders error kind with correct icon and styling" do
      component = described_class.new(text: "Error!", kind: :error)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.bg-rose-50")
      expect(output).to have_css("i.fa-circle-xmark")
    end

    it "accepts a custom icon" do
      component = described_class.new(text: "Custom", icon: "fa-bell")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("i.fa-bell")
    end
  end
end
