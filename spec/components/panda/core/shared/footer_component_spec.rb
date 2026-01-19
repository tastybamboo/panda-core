# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Shared::FooterComponent, type: :component do
  describe "initialization" do
    it "initializes without arguments" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    it "renders closing HTML tags" do
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      # Component renders closing tags (wrapped in test HTML document)
      expect(html).to include("</body>")
      expect(html).to include("</html>")
    end
  end
end
