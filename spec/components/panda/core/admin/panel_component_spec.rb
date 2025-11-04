# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::PanelComponent do
  describe "rendering" do
    it "renders a panel with heading and body" do
      component = described_class.new do |panel|
        panel.heading(text: "Recent Activity")
        panel.body { "Activity content goes here" }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.rounded-lg.shadow-md")
      expect(output).to have_css("h3.text-white", text: "Recent Activity")
      expect(output).to have_text("Activity content goes here")
    end

    it "renders panel without heading" do
      component = described_class.new do |panel|
        panel.body { "Just body content" }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.bg-white.rounded-b-lg")
      expect(output).to have_text("Just body content")
    end

    it "renders panel without body" do
      component = described_class.new do |panel|
        panel.heading(text: "Empty Panel")
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("h3", text: "Empty Panel")
      expect(output).to have_css("div.bg-white.rounded-b-lg")
    end

    it "applies panel styling to heading" do
      component = described_class.new do |panel|
        panel.heading(text: "Statistics")
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("h3.text-base.font-medium.px-4.py-3.text-white")
    end
  end
end
