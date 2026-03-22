# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::BreadcrumbsComponent, type: :component do
  CrumbStub = Struct.new(:name, :path, keyword_init: true) unless defined?(CrumbStub)
  let(:crumb1) { CrumbStub.new(name: "People", path: "/admin/people") }
  let(:crumb2) { CrumbStub.new(name: "Alice Smith", path: "/admin/people/1") }

  describe "rendering" do
    it "renders a nav element with Breadcrumb aria-label" do
      component = described_class.new(breadcrumbs: [crumb1])
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css('nav[aria-label="Breadcrumb"]')
    end

    it "renders a home link" do
      component = described_class.new(breadcrumbs: [])
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("a i.fa-house")
      expect(output).to have_css("span.sr-only", text: "Home")
    end

    it "renders breadcrumb links" do
      component = described_class.new(breadcrumbs: [crumb1, crumb2])
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_link("People", href: "/admin/people")
      expect(output).to have_link("Alice Smith", href: "/admin/people/1")
    end

    it "renders chevron separators between items" do
      component = described_class.new(breadcrumbs: [crumb1, crumb2])
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("i.fa-chevron-right", count: 2)
    end
  end
end
