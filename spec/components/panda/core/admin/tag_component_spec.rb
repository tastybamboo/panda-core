# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TagComponent, type: :component do
  describe "rendering" do
    it "renders a tag with default active status" do
      component = described_class.new(status: :active)
      html = render_inline(component).to_html

      expect(html).to include("bg-[var(--panda-badge-success-bg,var(--color-emerald-50))]")
      expect(html).to include("text-[var(--panda-badge-success-fg,var(--color-emerald-600))]")
      expect(Capybara.string(html)).to have_text("Active")
    end

    it "renders a draft tag with amber styling" do
      component = described_class.new(status: :draft)
      html = render_inline(component).to_html

      expect(html).to include("bg-[var(--panda-badge-warning-bg,var(--color-amber-50))]")
      expect(html).to include("text-[var(--panda-badge-warning-fg,var(--color-amber-600))]")
      expect(Capybara.string(html)).to have_text("Draft")
    end

    it "renders a tag with custom text" do
      component = described_class.new(status: :active, text: "Published")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Published")
    end

    it "renders an inactive tag" do
      component = described_class.new(status: :inactive)
      html = render_inline(component).to_html

      expect(html).to include("bg-[var(--panda-badge-neutral-bg,var(--color-gray-100))]")
      expect(html).to include("text-[var(--panda-badge-neutral-fg,var(--color-gray-600))]")
      expect(Capybara.string(html)).to have_text("Inactive")
    end
  end

  describe "theming" do
    it "maps every status/type to a badge tone whose var() fallback matches today's literal Tailwind colour (regression: no visual change for the default theme)" do
      {
        active: %w[success], live: %w[success], draft: %w[warning],
        inactive: %w[neutral], hidden: %w[neutral], auto: %w[info],
        warning: %w[error], static: %w[neutral]
      }.each do |status, (tone)|
        html = render_inline(described_class.new(status: status)).to_html
        expect(html).to include("--panda-badge-#{tone}-bg"), "expected #{status} to use the #{tone} badge tone"
      end
    end
  end
end
