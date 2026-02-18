# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::SearchFilterBarComponent, type: :component do
  let(:url) { "/admin/users" }

  describe "rendering" do
    it "renders a search input with magnifying glass icon" do
      render_inline(described_class.new(url: url))
      output = Capybara.string(rendered_content)

      expect(output).to have_css("i.fa-solid.fa-magnifying-glass")
      expect(output).to have_css("input[type='text'][name='q']")
    end

    it "renders a form with GET method" do
      render_inline(described_class.new(url: url))
      output = Capybara.string(rendered_content)

      expect(output).to have_css("form[action='/admin/users'][method='get']")
    end

    it "renders a Filter submit button" do
      render_inline(described_class.new(url: url))
      output = Capybara.string(rendered_content)

      expect(output).to have_css("input[type='submit'][value='Filter']")
    end

    it "uses custom search name" do
      render_inline(described_class.new(url: url, search_name: :search))
      output = Capybara.string(rendered_content)

      expect(output).to have_css("input[name='search']")
    end

    it "populates search value" do
      render_inline(described_class.new(url: url, search_value: "test query"))
      output = Capybara.string(rendered_content)

      expect(output).to have_css("input[value='test query']")
    end

    it "uses custom placeholder" do
      render_inline(described_class.new(url: url, search_placeholder: "Search by name..."))
      output = Capybara.string(rendered_content)

      expect(output).to have_css("input[placeholder='Search by name...']")
    end

    it "applies primary-600 focus ring to search input" do
      render_inline(described_class.new(url: url))
      output = Capybara.string(rendered_content)

      expect(output).to have_css("input.focus-visible\\:outline-primary-600")
    end
  end

  describe "clear link" do
    it "does not render clear link when show_clear is false" do
      render_inline(described_class.new(url: url, show_clear: false))
      output = Capybara.string(rendered_content)

      expect(output).not_to have_link("Clear")
    end

    it "renders clear link when show_clear is true" do
      render_inline(described_class.new(url: url, show_clear: true))
      output = Capybara.string(rendered_content)

      expect(output).to have_link("Clear", href: url)
    end

    it "uses custom clear_url" do
      render_inline(described_class.new(url: url, show_clear: true, clear_url: "/admin/users/reset"))
      output = Capybara.string(rendered_content)

      expect(output).to have_link("Clear", href: "/admin/users/reset")
    end
  end

  describe "filters slot" do
    it "renders filter content in the filters area" do
      render_inline(described_class.new(url: url)) do |bar|
        bar.with_filter { "<select name='status'><option>All</option></select>".html_safe }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("select[name='status']")
    end

    it "renders multiple filters" do
      render_inline(described_class.new(url: url)) do |bar|
        bar.with_filter { "<select name='status'><option>All</option></select>".html_safe }
        bar.with_filter { "<select name='role'><option>All</option></select>".html_safe }
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("select[name='status']")
      expect(output).to have_css("select[name='role']")
    end
  end

  describe "#select_classes" do
    it "returns consistent select styling" do
      component = described_class.new(url: url)
      classes = component.select_classes

      expect(classes).to include("ring-1")
      expect(classes).to include("ring-gray-300")
      expect(classes).to include("focus:ring-primary-600")
    end
  end
end
