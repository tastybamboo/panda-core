# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::PanelComponent, type: :component do
  describe "rendering" do
    it "renders a panel with heading and body" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot(text: "Recent Activity")
        panel.with_body { "Activity content goes here" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("div.rounded-lg.shadow-md")
      expect(output).to have_css("h3.text-white", text: "Recent Activity")
      expect(output).to have_text("Activity content goes here")
    end

    it "renders panel without heading" do
      render_inline(described_class.new) do |panel|
        panel.with_body { "Just body content" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("div.bg-white.rounded-b-lg")
      expect(output).to have_text("Just body content")
    end

    it "renders panel without body" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot(text: "Empty Panel")
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("h3", text: "Empty Panel")
      expect(output).to have_css("div.bg-white.rounded-b-lg")
    end

    it "applies panel styling to heading" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot(text: "Statistics")
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("h3.text-base.font-medium.px-4.py-3.text-white")
    end
  end
end
