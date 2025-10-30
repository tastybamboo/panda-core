# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::SlideoverComponent do
  describe "rendering" do
    # Note: SlideoverComponent uses helpers.content_for which requires a full view context
    # These tests verify the component structure but may not work in isolation

    it "creates a component with default title" do
      component = described_class.new do
        "Slideover content"
      end

      expect(component).to be_a(described_class)
      expect(component.instance_variable_get(:@title)).to eq("Settings")
    end

    it "creates a component with custom title" do
      component = described_class.new(title: "Edit Settings") do
        "Content"
      end

      expect(component).to be_a(described_class)
      expect(component.instance_variable_get(:@title)).to eq("Edit Settings")
    end
  end
end
