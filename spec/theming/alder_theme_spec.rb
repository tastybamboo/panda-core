# frozen_string_literal: true

require "rails_helper"

# Asserts the compiled, committed panda-core.css includes the alder theme
# block with the expected values (see app/assets/tailwind/application.css
# for the source and app/assets/tailwind/application.css's "Panda admin
# chrome tokens" comment for the full token catalogue). This is a
# compiled-artifact check rather than a component check: it guards against a
# source edit landing without a matching `bin/compile-css` /
# `rake panda:compile_css` run.
RSpec.describe "compiled panda-core.css alder theme" do
  let(:compiled_css) do
    path = Panda::Core::Engine.root.join("public/panda-core-assets/panda-core.css")
    File.read(path)
  end

  it "defines the alder theme block" do
    expect(compiled_css).to match(/html\[data-theme=['"]?alder['"]?\]\{/)
  end

  it "does not define an ocean theme block (renamed back to sky)" do
    expect(compiled_css).not_to match(/data-theme=['"]?ocean['"]?/)
  end

  it "defines the sky theme block" do
    expect(compiled_css).to match(/html\[data-theme=['"]?sky['"]?\]\{/)
  end

  it "sets the alder primary scale to Alder CRM's Deep Roots palette" do
    alder_block = compiled_css[/html\[data-theme=['"]?alder['"]?\]\{[^}]*\}/i]

    expect(alder_block).to be_present
    expect(alder_block.downcase).to include("--color-primary-400:#52b788")
    expect(alder_block.downcase).to include("--color-primary-600:#1b4332")
    expect(alder_block.downcase).to include("--gradient-admin-from:#1b4332")
    expect(alder_block.downcase).to include("--gradient-admin-to:#2d6a4f")
  end

  it "sets the alder panda-* chrome tokens to Alder CRM's spec" do
    alder_block = compiled_css[/html\[data-theme=['"]?alder['"]?\]\{[^}]*\}/i].downcase

    expect(alder_block).to include("--panda-panel-bg:#fff")
    expect(alder_block).to include("--panda-panel-border:#f1f3f5")
    expect(alder_block).to include("--panda-panel-radius:12px")
    expect(alder_block).to include("--panda-table-header-bg:transparent")
    expect(alder_block).to include("--panda-table-border:#f1f3f5")
    expect(alder_block).to include("--panda-table-row-border:#f8f9fa")
    expect(alder_block).to include("--panda-table-cell-color:#495057")
    expect(alder_block).to include("--panda-badge-success-bg:#d3f9d8")
    expect(alder_block).to include("--panda-badge-success-fg:#2b8a3e")
    expect(alder_block).to include("--panda-badge-warning-bg:#fff3bf")
    expect(alder_block).to include("--panda-badge-warning-fg:#e67700")
    expect(alder_block).to include("--panda-badge-info-bg:#d0ebff")
    expect(alder_block).to include("--panda-badge-info-fg:#1971c2")
    expect(alder_block).to include("--panda-badge-error-bg:#ffe3e3")
    expect(alder_block).to include("--panda-badge-error-fg:#e03131")
    expect(alder_block).to include("--panda-badge-neutral-bg:#f1f3f5")
    expect(alder_block).to include("--panda-badge-neutral-fg:#868e96")
    expect(alder_block).to include("--panda-input-border:#dee2e6")
    expect(alder_block).to include("--panda-input-radius:8px")
    expect(alder_block).to include("--panda-select-trigger-border:#dee2e6")
  end

  it "keeps the default/sky themes' panda-* tokens chained to existing tokens (pixel-identical fallback)" do
    # LightningCSS splits html[data-theme=default]/[sky] into multiple
    # fragments (a `color-mix()` progressive-enhancement `@supports` block),
    # so this checks the whole file rather than one extracted block — these
    # var-chain values are specific enough that a whole-file match still
    # proves the non-alder themes never got a hardcoded literal here.
    expect(compiled_css).to include("--panda-panel-bg:var(--color-white)")
    expect(compiled_css).to include("--panda-panel-border:var(--color-gray-200)")
    expect(compiled_css).to include("--panda-table-header-bg:var(--color-gray-50)")
    expect(compiled_css).to include("--panda-badge-success-bg:var(--color-emerald-50)")
    expect(compiled_css).to include("--panda-input-border:var(--color-gray-300)")
  end
end
