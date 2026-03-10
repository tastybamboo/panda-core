# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::Navigation::ItemComponent, type: :component do
  let(:base_attrs) { {label: "Dashboard", icon: "fa-solid fa-house", path: "/admin"} }

  describe "badge rendering" do
    it "renders a badge with default color" do
      component = described_class.new(**base_attrs, badge: 5)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("span.rounded-full", text: "5")
      expect(output).to have_css("span[style*='#52B788']")
    end

    it "renders a badge with custom color" do
      component = described_class.new(**base_attrs, badge: 12, badge_color: "#FF0000")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("span.rounded-full", text: "12")
      expect(output).to have_css("span[style*='#FF0000']")
    end

    it "does not render a badge when badge is nil" do
      component = described_class.new(**base_attrs)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).not_to have_css("span.rounded-full")
    end

    it "renders a badge on expandable items with children" do
      component = described_class.new(**base_attrs.except(:path), badge: 3, menu_id: "test-menu")
      render_inline(component) do |nav_item|
        nav_item.with_sub_item(label: "Child", path: "/admin/child", active: false)
      end
      output = Capybara.string(rendered_content)

      expect(output).to have_css("span.rounded-full", text: "3")
    end
  end
end
