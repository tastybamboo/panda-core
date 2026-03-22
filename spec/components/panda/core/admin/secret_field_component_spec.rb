# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::SecretFieldComponent, type: :component do
  describe "rendering" do
    it "renders a masked value by default" do
      component = described_class.new(value: "sk_live_abc123xyz")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("code", text: /\u2022+3xyz/)
      expect(output).to have_no_text("sk_live_abc123xyz")
    end

    it "shows only bullets for short values" do
      component = described_class.new(value: "abc")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("code", text: "\u2022\u2022\u2022")
    end

    it "renders a reveal toggle button" do
      component = described_class.new(value: "secret123")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('button[aria-label="Reveal secret value"]')
      expect(output).to have_text("Reveal")
    end

    it "renders a copy button" do
      component = described_class.new(value: "secret123")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('button[aria-label="Copy secret value to clipboard"]')
      expect(output).to have_text("Copy")
    end

    it "renders with the clipboard Stimulus controller" do
      component = described_class.new(value: "secret123")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('[data-controller="clipboard"]')
    end
  end
end
