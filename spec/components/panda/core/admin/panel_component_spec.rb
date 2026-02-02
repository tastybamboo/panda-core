# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::PanelComponent, type: :component do
  describe "rendering" do
    it "renders a panel with heading and body" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot { "Recent Activity" }
        panel.with_body_slot { "Activity content goes here" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("div.rounded-2xl.shadow-sm")
      expect(output).to have_css("div.text-gray-700", text: "Recent Activity")
      expect(output).to have_text("Activity content goes here")
    end

    it "renders panel without heading" do
      render_inline(described_class.new) do |panel|
        panel.with_body_slot { "Just body content" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("div.p-4.text-black")
      expect(output).to have_text("Just body content")
    end

    it "renders panel without body" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot { "Empty Panel" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_text("Empty Panel")
      expect(output).to have_css("div.bg-white.rounded-2xl")
    end

    it "applies panel styling to heading" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot { "Statistics" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("div.text-sm.font-medium.px-4.py-3.text-gray-700")
    end
  end
end
