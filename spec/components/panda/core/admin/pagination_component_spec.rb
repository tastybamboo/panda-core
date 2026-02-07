# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::PaginationComponent, type: :component do
  let(:default_params) do
    {page: 2, total_pages: 5, total_count: 120, per_page: 25, item_name: "users"}
  end

  describe "#render?" do
    it "renders when total_pages > 1" do
      with_request_url "/admin/users" do
        component = described_class.new(**default_params)
        render_inline(component)
        expect(page).to have_css("nav")
      end
    end

    it "does not render when total_pages is 1" do
      component = described_class.new(**default_params.merge(total_pages: 1))
      render_inline(component)
      expect(page).not_to have_css("nav")
    end
  end

  describe "summary text" do
    it "shows correct item range and total" do
      with_request_url "/admin/users" do
        component = described_class.new(**default_params)
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_text("Showing 26 to 50 of 120 users")
      end
    end

    it "caps the last item at total_count" do
      with_request_url "/admin/users" do
        component = described_class.new(page: 5, total_pages: 5, total_count: 120, per_page: 25, item_name: "users")
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_text("Showing 101 to 120 of 120 users")
      end
    end
  end

  describe "navigation" do
    it "shows previous link when not on first page" do
      with_request_url "/admin/users" do
        component = described_class.new(**default_params)
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_css("i.fa-solid.fa-chevron-left")
      end
    end

    it "hides previous link on first page" do
      with_request_url "/admin/users" do
        component = described_class.new(**default_params.merge(page: 1))
        output = Capybara.string(render_inline(component).to_html)

        expect(output).not_to have_css("i.fa-solid.fa-chevron-left")
      end
    end

    it "shows next link when not on last page" do
      with_request_url "/admin/users" do
        component = described_class.new(**default_params)
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_css("i.fa-solid.fa-chevron-right")
      end
    end

    it "hides next link on last page" do
      with_request_url "/admin/users" do
        component = described_class.new(**default_params.merge(page: 5))
        output = Capybara.string(render_inline(component).to_html)

        expect(output).not_to have_css("i.fa-solid.fa-chevron-right")
      end
    end

    it "highlights the current page" do
      with_request_url "/admin/users" do
        component = described_class.new(**default_params)
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_css("span.bg-primary-600", text: "2")
      end
    end

    it "shows ellipsis for distant pages" do
      with_request_url "/admin/users" do
        component = described_class.new(page: 1, total_pages: 10, total_count: 250, per_page: 25, item_name: "items")
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_text("…")
      end
    end
  end

  describe "item_name" do
    it "defaults to items" do
      with_request_url "/admin/users" do
        component = described_class.new(page: 1, total_pages: 3, total_count: 60, per_page: 25)
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_text("of 60 items")
      end
    end

    it "uses custom item_name" do
      with_request_url "/admin/users" do
        component = described_class.new(page: 1, total_pages: 3, total_count: 60, per_page: 25, item_name: "activities")
        output = Capybara.string(render_inline(component).to_html)

        expect(output).to have_text("of 60 activities")
      end
    end
  end
end
