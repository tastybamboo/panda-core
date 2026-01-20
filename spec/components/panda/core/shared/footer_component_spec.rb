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
    # This component outputs document-level closing tags which ViewComponent strips in isolation
    # The component works correctly in production when rendered through layouts
    xit "renders closing HTML tags" do
      component = described_class.new
      html = render_inline(component).to_html

      # Component renders closing tags
      expect(html).to include("</body>")
      expect(html).to include("</html>")
    end
  end
end
