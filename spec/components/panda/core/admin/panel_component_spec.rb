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

      expect(output).to have_css("div.shadow-sm")
      expect(rendered_content).to include("rounded-[var(--panda-panel-radius,var(--radius-2xl))]")
      expect(output).to have_css("div.text-gray-500", text: "Recent Activity")
      expect(output).to have_text("Activity content goes here")
    end

    it "renders panel without heading" do
      render_inline(described_class.new) do |panel|
        panel.with_body_slot { "Just body content" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("div.px-4.py-3.text-black")
      expect(output).to have_text("Just body content")
    end

    it "renders panel without body" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot { "Empty Panel" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_text("Empty Panel")
      expect(rendered_content).to include("bg-[var(--panda-panel-bg,var(--color-white))]")
      expect(rendered_content).to include("rounded-[var(--panda-panel-radius,var(--radius-2xl))]")
    end

    it "applies panel styling to heading" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot { "Statistics" }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("div.text-sm.font-medium.px-4.py-3.text-gray-500")
    end
  end

  describe "theming" do
    it "renders bg/border/radius as arbitrary-value utilities whose fallbacks match today's literal colours (regression: no visual change for the default theme)" do
      render_inline(described_class.new) do |panel|
        panel.with_heading_slot { "Recent Activity" }
      end
      html = rendered_content

      expect(html).to include("bg-[var(--panda-panel-bg,var(--color-white))]")
      expect(html).to include("border-[var(--panda-panel-border,var(--color-gray-200))]")
      expect(html).to include("rounded-[var(--panda-panel-radius,var(--radius-2xl))]")
    end
  end
end
