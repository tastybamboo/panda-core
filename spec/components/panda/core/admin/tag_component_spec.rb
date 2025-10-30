# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TagComponent do
  describe "rendering" do
    it "renders a tag with default active status" do
      component = described_class.new(status: :active)
      output = Capybara.string(component.call)

      expect(output).to have_css("span.bg-green-600")
      expect(output).to have_text("Active")
    end

    it "renders a draft tag with yellow styling" do
      component = described_class.new(status: :draft)
      output = Capybara.string(component.call)

      expect(output).to have_css("span.bg-yellow-400")
      expect(output).to have_text("Draft")
    end

    it "renders a tag with custom text" do
      component = described_class.new(status: :active, text: "Published")
      output = Capybara.string(component.call)

      expect(output).to have_text("Published")
    end

    it "renders an inactive tag" do
      component = described_class.new(status: :inactive)
      output = Capybara.string(component.call)

      expect(output).to have_css("span.bg-white")
      expect(output).to have_text("Inactive")
    end
  end
end
