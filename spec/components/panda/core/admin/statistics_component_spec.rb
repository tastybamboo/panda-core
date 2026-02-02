# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::StatisticsComponent, type: :component do
  describe "rendering" do
    it "renders a statistic with string value" do
      component = described_class.new(metric: "Total Users", value: "1,234")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("dt", text: "Total Users")
      expect(output).to have_css("dd", text: "1,234")
    end

    it "renders a statistic with integer value" do
      component = described_class.new(metric: "Active Pages", value: 42)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("dt", text: "Active Pages")
      expect(output).to have_css("dd", text: "42")
    end

    it "renders a statistic with float value" do
      component = described_class.new(metric: "Average Rating", value: 4.7)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("dt", text: "Average Rating")
      expect(output).to have_css("dd", text: "4.7")
    end

    it "renders with nil value" do
      component = described_class.new(metric: "Pending", value: nil)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("dt", text: "Pending")
      expect(output).to have_css("dd")
    end

    it "applies card styling" do
      component = described_class.new(metric: "Total", value: 100)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.bg-white.rounded-2xl")
    end

    it "applies border and padding" do
      component = described_class.new(metric: "Count", value: 5)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.border.border-gray-200.p-4.rounded-2xl")
    end

    it "truncates long metric names" do
      component = described_class.new(
        metric: "Very Long Metric Name That Should Be Truncated",
        value: 999
      )
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("dt.truncate")
    end

    it "applies correct typography to value" do
      component = described_class.new(metric: "Total", value: 100)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("dd.text-2xl.font-semibold.tracking-tight")
    end
  end
end
