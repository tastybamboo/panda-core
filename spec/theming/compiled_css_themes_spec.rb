# frozen_string_literal: true

require "rails_helper"

# Asserts the compiled, committed panda-core.css ships the theme
# infrastructure (see app/assets/tailwind/application.css for the source and
# its "Panda admin chrome tokens" comment for the full token catalogue).
# This is a compiled-artifact check rather than a component check: it guards
# against a source edit landing without a matching `bin/compile-css` /
# `rake panda:compile_css` run.
RSpec.describe "compiled panda-core.css themes" do
  let(:compiled_css) do
    path = Panda::Core::Engine.root.join("public/panda-core-assets/panda-core.css")
    File.read(path)
  end

  it "defines the sky theme block (matching available_themes' 'sky' value)" do
    expect(compiled_css).to match(/html\[data-theme=['"]?sky['"]?\]\{/)
  end

  it "does not define an ocean theme block (renamed back to sky)" do
    expect(compiled_css).not_to match(/data-theme=['"]?ocean['"]?/)
  end

  it "does not ship any host-app theme block (themes are bring-your-own)" do
    expect(compiled_css).not_to match(/data-theme=['"]?alder['"]?/)
  end

  it "keeps the default/sky themes' panda-* tokens chained to existing tokens (pixel-identical fallback)" do
    # LightningCSS splits html[data-theme=default]/[sky] into multiple
    # fragments (a `color-mix()` progressive-enhancement `@supports` block),
    # so this checks the whole file rather than one extracted block — these
    # var-chain values are specific enough that a whole-file match still
    # proves the built-in themes never got a hardcoded literal here.
    expect(compiled_css).to include("--panda-panel-bg:var(--color-white)")
    expect(compiled_css).to include("--panda-panel-border:var(--color-gray-200)")
    expect(compiled_css).to include("--panda-table-header-bg:var(--color-gray-50)")
    expect(compiled_css).to include("--panda-badge-success-bg:var(--color-emerald-50)")
    expect(compiled_css).to include("--panda-input-border:var(--color-gray-300)")
  end

  it "generates the arbitrary-value utilities the components consume" do
    expect(compiled_css).to include("var(--panda-panel-bg,var(--color-white))")
    expect(compiled_css).to include("var(--panda-badge-success-bg,var(--color-emerald-50))")
    expect(compiled_css).to include("var(--panda-input-radius,var(--radius-xl))")
    expect(compiled_css).to include("var(--panda-select-trigger-border,var(--color-gray-200))")
  end
end
