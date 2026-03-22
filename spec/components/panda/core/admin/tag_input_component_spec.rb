# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TagInputComponent, type: :component do
  TagStub = Struct.new(:id, :name, :display_colour, keyword_init: true) unless defined?(TagStub)
  let(:tag1) { TagStub.new(id: 1, name: "Priority", display_colour: "#dc2626") }
  let(:tag2) { TagStub.new(id: 2, name: "Follow-up", display_colour: "#2563eb") }

  describe "rendering" do
    it "renders a search input" do
      component = described_class.new(tags_url: "/tags/search")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('input[type="text"][placeholder="Search or add tags..."]')
    end

    it "renders with the tag-input Stimulus controller" do
      component = described_class.new(tags_url: "/tags/search")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('[data-controller="tag-input"]')
    end

    it "renders selected tags as pills" do
      component = described_class.new(tags_url: "/tags/search", selected_tags: [tag1, tag2])
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Priority")
      expect(output).to have_text("Follow-up")
    end

    it "renders hidden inputs for selected tags" do
      component = described_class.new(tags_url: "/tags/search", selected_tags: [tag1])
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('input[type="hidden"][name="tag_ids[]"][value="1"]', visible: :hidden)
    end

    it "sets the correct data attributes" do
      component = described_class.new(tags_url: "/tags/search", selected_tags: [tag1])
      html = render_inline(component).to_html

      expect(html).to include('data-tag-input-url-value="/tags/search"')
      expect(html).to include("data-tag-input-selected-value=")
    end
  end
end
