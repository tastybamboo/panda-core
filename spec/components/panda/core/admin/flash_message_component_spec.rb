# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FlashMessageComponent, type: :component do
  describe "rendering" do
    it "renders a success flash message" do
      component = described_class.new(message: "Saved successfully", kind: :success)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Saved successfully")
      expect(output).to have_css("i.fa-circle-check")
      expect(output).to have_css(".text-emerald-600")
    end

    it "renders an error flash message" do
      component = described_class.new(message: "An error occurred", kind: :error)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("An error occurred")
      expect(output).to have_css("i.fa-circle-xmark")
      expect(output).to have_css(".text-rose-600")
    end

    it "renders a warning flash message" do
      component = described_class.new(message: "Warning message", kind: :warning)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Warning message")
      expect(output).to have_css("i.fa-triangle-exclamation")
      expect(output).to have_css(".text-amber-600")
    end

    it "renders a notice/info flash message" do
      component = described_class.new(message: "Information", kind: :notice)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Information")
      expect(output).to have_css("i.fa-circle-info")
      expect(output).to have_css(".text-sky-600")
    end

    it "renders with subtitle when provided" do
      component = described_class.new(
        message: "Successfully saved!",
        kind: :success,
        subtitle: "Anyone with a link can now view this file."
      )
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Successfully saved!")
      expect(output).to have_text("Anyone with a link can now view this file.")
      expect(output).to have_css(".flash-message-subtitle")
    end

    it "renders without subtitle when not provided" do
      component = described_class.new(message: "Test", kind: :notice)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).not_to have_css(".flash-message-subtitle")
    end

    it "includes close button" do
      component = described_class.new(message: "Test", kind: :notice)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("button[data-action='alert#close']")
    end

    it "applies rounded and shadow styling" do
      component = described_class.new(message: "Test", kind: :success)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css(".rounded-2xl.shadow-lg")
      expect(output).to have_css(".bg-emerald-50")
    end

    it "applies tone-based background colors" do
      component = described_class.new(message: "Test", kind: :success)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css(".bg-emerald-50.text-emerald-700")
    end

    it "sets temporary dismissal by default" do
      component = described_class.new(message: "Test", kind: :notice)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("[data-alert-dismiss-after-value='5000']")
    end

    it "does not set auto-dismiss when temporary is false" do
      component = described_class.new(message: "Test", kind: :notice, temporary: false)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).not_to have_css("[data-alert-dismiss-after-value]")
    end

    it "uses FontAwesome icons" do
      component = described_class.new(message: "Test", kind: :success)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("i.fa-solid")
      expect(output).to have_css("i.size-5")
    end
  end
end
