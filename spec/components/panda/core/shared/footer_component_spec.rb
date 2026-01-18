# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Shared::FooterComponent do
  describe "initialization" do
    it "initializes without arguments" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    it "renders closing HTML tags" do
      component = described_class.new
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html.strip).to eq("</body>\n</html>")
    end
  end
end
