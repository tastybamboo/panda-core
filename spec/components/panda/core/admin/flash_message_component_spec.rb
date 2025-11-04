# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FlashMessageComponent do
  describe "rendering" do
    it "renders a success flash message" do
      component = described_class.new(message: "Saved successfully", kind: :success)
      output = Capybara.string(component.call)

      expect(output).to have_text("Saved successfully")
      expect(output).to have_css(".text-green-600")
      expect(output).to have_css("i.fa-circle-check")
    end

    it "renders an error flash message" do
      component = described_class.new(message: "An error occurred", kind: :error)
      output = Capybara.string(component.call)

      expect(output).to have_text("An error occurred")
      expect(output).to have_css(".text-red-600")
      expect(output).to have_css("i.fa-circle-xmark")
    end

    it "renders a warning flash message" do
      component = described_class.new(message: "Warning message", kind: :warning)
      output = Capybara.string(component.call)

      expect(output).to have_text("Warning message")
      expect(output).to have_css(".text-yellow-600")
      expect(output).to have_css("i.fa-triangle-exclamation")
    end

    it "includes close button" do
      component = described_class.new(message: "Test", kind: :notice)
      output = Capybara.string(component.call)

      expect(output).to have_css("button[data-action='alert#close']")
    end

    it "sets temporary dismissal by default" do
      component = described_class.new(message: "Test", kind: :notice)
      output = Capybara.string(component.call)

      expect(output).to have_css("[data-alert-dismiss-after-value='5000']")
    end

    it "does not set auto-dismiss when temporary is false" do
      component = described_class.new(message: "Test", kind: :notice, temporary: false)
      output = Capybara.string(component.call)

      expect(output).not_to have_css("[data-alert-dismiss-after-value]")
    end
  end
end
