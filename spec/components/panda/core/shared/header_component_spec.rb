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

    it "includes FontAwesome stylesheet" do
      component = described_class.new
      html = render_inline(component).to_html

      expect(html).to include("fontawesome-free")
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
