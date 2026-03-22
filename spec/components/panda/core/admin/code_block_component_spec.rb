# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::CodeBlockComponent, type: :component do
  describe "rendering" do
    it "renders code passed via the code parameter" do
      component = described_class.new(code: "puts 'hello'")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("pre code", text: "puts 'hello'")
    end

    it "renders code passed via block content" do
      component = described_class.new
      output = Capybara.string(render_inline(component) { "SELECT * FROM users" }.to_html)

      expect(output).to have_css("pre code", text: "SELECT * FROM users")
    end

    it "applies styling classes" do
      component = described_class.new(code: "x = 1")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("pre.font-mono")
    end
  end
end
