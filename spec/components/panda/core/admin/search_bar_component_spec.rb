# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::SearchBarComponent, type: :component do
  let(:searchable_class) do
    Class.new do
      def self.admin_search(query, limit: 5)
        []
      end
    end
  end

  around do |example|
    original_providers = Panda::Core::SearchRegistry.providers.dup
    example.run
    Panda::Core::SearchRegistry.reset!
    original_providers.each do |p|
      Panda::Core::SearchRegistry.register(name: p[:name], search_class: p[:search_class])
    end
  end

  describe "rendering" do
    it "renders a search input when search providers are registered" do
      Panda::Core::SearchRegistry.register(name: "test", search_class: searchable_class)
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('input[type="text"][placeholder="Search..."]')
    end

    it "renders the keyboard shortcut hint" do
      Panda::Core::SearchRegistry.register(name: "test", search_class: searchable_class)
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("kbd")
    end

    it "renders with the global-search Stimulus controller" do
      Panda::Core::SearchRegistry.register(name: "test", search_class: searchable_class)
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('[data-controller="global-search"]')
    end

    it "does not render when no search providers are registered" do
      Panda::Core::SearchRegistry.reset!
      component = described_class.new
      html = render_inline(component).to_html

      expect(html.strip).to eq("")
    end
  end
end
