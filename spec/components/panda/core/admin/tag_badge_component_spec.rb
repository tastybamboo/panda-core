# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TagBadgeComponent, type: :component do
  TagStub = Struct.new(:id, :name, :display_colour, keyword_init: true) unless defined?(TagStub)
  let(:tag_object) { TagStub.new(id: 1, name: "Urgent", display_colour: "#e11d48") }

  describe "rendering" do
    it "renders the tag name" do
      component = described_class.new(tag: tag_object)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Urgent")
    end

    it "applies colour styling from the tag" do
      component = described_class.new(tag: tag_object)
      html = render_inline(component).to_html

      expect(html).to include("background-color: #e11d48")
      expect(html).to include("color: #e11d48")
    end

    it "does not render a remove button when not removable" do
      component = described_class.new(tag: tag_object, removable: false)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_no_css("button")
    end

    it "renders a remove button when removable" do
      component = described_class.new(tag: tag_object, removable: true)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("button")
    end
  end
end
