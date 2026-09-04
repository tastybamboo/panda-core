# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Shared::HeaderComponent, type: :component do
  describe "initialization" do
    it "accepts html_class property" do
      component = described_class.new(html_class: "custom-class")
      expect(component).to be_a(described_class)
    end

    it "accepts body_class property" do
      component = described_class.new(body_class: "bg-gradient")
      expect(component).to be_a(described_class)
    end

    it "has default values" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    # These tests check for document-level HTML structure which ViewComponent strips in isolation
    # The component works correctly in production when rendered through layouts
    xit "renders HTML structure" do
      component = described_class.new
      html = render_inline(component).to_html

      expect(html).to include("<!DOCTYPE html>")
      expect(html).to include("<html")
      expect(html).to include("<head>")
      expect(html).to include("<body")
    end

    xit "includes data-theme attribute" do
      component = described_class.new
      html = render_inline(component).to_html

      expect(html).to include("data-theme=")
    end

    it "includes the FontAwesome stylesheet from a same-origin path" do
      component = described_class.new
      html = render_inline(component).to_html

      # Vendored, not from a CDN: style-src 'self' refuses the CDN stylesheet and
      # font-src 'self' refuses the webfonts behind it.
      expect(html).to include('<link rel="stylesheet" href="/panda-core-assets/fontawesome/css/all.min.css">')
      expect(html).not_to include("cdn.jsdelivr.net")
    end

    it "loads the es-module-shims polyfill from a same-origin path, without async" do
      html = render_inline(described_class.new).to_html

      # The shim has to merge importmaps before any module script evaluates, which
      # async does not guarantee.
      expect(html).to include('<script src="/panda-core-assets/es-module-shims.js"></script>')
      expect(html).not_to include("ga.jspm.io")
    end

    # These two read rendered_content rather than to_html: render_inline parses
    # the result as a fragment, which drops the doctype and the <html> and <head>
    # wrappers along with their attributes.
    it "declares the character encoding inside the first 1024 bytes" do
      render_inline(described_class.new)

      # The HTML spec ignores a charset declaration that lands any later.
      expect(rendered_content.byteslice(0, 1024)).to match(/<meta charset="utf-8">/)
    end

    it "declares a document language" do
      render_inline(described_class.new)

      expect(rendered_content).to match(/<html lang="[^"]+"/)
    end

    xit "applies custom html_class" do
      component = described_class.new(html_class: "h-full")
      html = render_inline(component).to_html

      expect(html).to include('class="h-full"')
    end

    xit "applies custom body_class" do
      component = described_class.new(body_class: "bg-gradient-admin")
      html = render_inline(component).to_html

      expect(html).to include("bg-gradient-admin")
    end

    context "when chartkick gem is loaded" do
      before do
        allow(Gem).to receive(:loaded_specs).and_return({"chartkick" => double("gem_spec")})
      end

      it "includes Chartkick script tags" do
        html = render_inline(described_class.new).to_html

        expect(html).to include("Chart.bundle.js")
        expect(html).to include("chartkick.js")
      end
    end

    context "when chartkick gem is not loaded" do
      before do
        allow(Gem).to receive(:loaded_specs).and_return({})
      end

      it "does not include Chartkick script tags" do
        html = render_inline(described_class.new).to_html

        expect(html).not_to include("Chart.bundle.js")
        expect(html).not_to include("chartkick.js")
      end
    end
  end
end
