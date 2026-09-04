# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::AssetHelper, type: :helper do
  describe "#panda_core_javascript" do
    context "when not using GitHub assets" do
      before do
        allow(Panda::Core::AssetLoader).to receive(:use_github_assets?).and_return(false)
      end

      it "generates an inline importmap" do
        result = helper.panda_core_javascript
        expect(result).to include('<script type="importmap"')
      end

      it "includes required JavaScript modules" do
        result = helper.panda_core_javascript
        expect(result).to include('"@hotwired/stimulus"')
        expect(result).to include('"@hotwired/turbo"')
        expect(result).to include('"panda/core/application"')
      end

      it "includes cropperjs from the importmap" do
        result = helper.panda_core_javascript
        expect(result).to include('"cropperjs"')
        expect(result).to include("/panda/core/vendor/cropperjs@2.1.0.js")
      end

      it "includes tailwindplus/elements from the importmap" do
        result = helper.panda_core_javascript
        expect(result).to include('"@tailwindplus/elements"')
        expect(result).to include("/panda/core/vendor/@tailwindplus--elements@1.0.22.js")
      end

      it "includes correct file paths with .js extension for local modules" do
        result = helper.panda_core_javascript
        expect(result).to include('"/panda/core/application.js"')
        expect(result).to include('"/panda/core/controllers/index.js"')
        expect(result).to include('"/panda/core/controllers/toggle_controller.js"')
        expect(result).not_to include('"/panda/core/application"') # Should not be missing .js
      end

      it "has no external CDN URLs in the importmap" do
        importmap_config = File.read(Panda::Core::Engine.root.join("config/importmap.rb"))
        cdn_pins = importmap_config.scan(/pin\s+"[^"]+",\s+to:\s+"(https:\/\/[^"]+)"/)
        expect(cdn_pins).to be_empty, "Expected no CDN URLs in importmap.rb but found: #{cdn_pins.flatten.join(", ")}"
      end

      it "includes all vendored packages from config/importmap.rb" do
        importmap_config = File.read(Panda::Core::Engine.root.join("config/importmap.rb"))

        # Extract vendored packages (those pinned to /panda/ paths)
        vendored_packages = []
        importmap_config.scan(/pin\s+"([^"]+)",\s+to:\s+"(\/panda\/[^"]+)"/) do |package, path|
          vendored_packages << {package: package, path: path}
        end

        result = helper.panda_core_javascript

        vendored_packages.each do |pkg|
          expect(result).to include(%("#{pkg[:package]}")),
            "Expected inline importmap to include #{pkg[:package]} from config/importmap.rb"
        end
      end
    end

    context "when using GitHub assets" do
      before do
        allow(Panda::Core::AssetLoader).to receive(:use_github_assets?).and_return(true)
      end

      it "still uses importmap (Rails 8 approach)" do
        result = helper.panda_core_javascript
        expect(result).to include('<script type="importmap"')
        expect(result).to include('"panda/core/application"')
      end
    end
  end

  describe "nonces" do
    # These tags are built as raw strings rather than through
    # javascript_importmap_tags, so nothing applies the nonce for us. Under
    # script-src 'self' an un-nonced inline script is dropped silently, taking
    # Turbo and every Stimulus controller with it.
    context "when the request carries a CSP nonce" do
      before do
        allow(helper).to receive(:content_security_policy_nonce).and_return("test-nonce-value")
      end

      it "nonces the importmap tag" do
        expect(helper.panda_core_importmap_tag).to include('<script type="importmap" nonce="test-nonce-value">')
      end

      it "nonces every module entry point" do
        tags = helper.panda_core_script_tags.scan(/<script type="module"[^>]*>/)

        expect(tags).not_to be_empty
        expect(tags).to all(include('nonce="test-nonce-value"'))
      end

      it "escapes the nonce it interpolates" do
        allow(helper).to receive(:content_security_policy_nonce).and_return(%(a"><script>x</script>))

        expect(helper.panda_core_importmap_tag).not_to include("<script>x</script>")
      end
    end

    context "when there is no nonce" do
      before do
        allow(helper).to receive(:content_security_policy_nonce).and_return(nil)
      end

      # An app with no CSP configured gets nil back. Emitting nonce="" there is
      # worse than emitting nothing: an empty nonce matches no policy.
      it "emits no nonce attribute at all" do
        result = helper.panda_core_javascript

        expect(result).to include('<script type="importmap">')
        expect(result).not_to include('nonce=""')
      end
    end
  end

  describe "#panda_core_importmap_tag and #panda_core_script_tags" do
    # A host app emitting its own importmap needs exactly one in the document:
    # browsers with native import-map support honour the first and ignore the
    # rest. Splitting the entry points out lets such an app merge Panda's pins
    # into its own importmap and still get the entry points.
    it "together produce what panda_core_javascript produces" do
      expect(helper.panda_core_javascript)
        .to eq(helper.panda_core_importmap_tag + helper.panda_core_script_tags)
    end

    it "emits entry points without an importmap" do
      expect(helper.panda_core_script_tags).not_to include("type=\"importmap\"")
      expect(helper.panda_core_script_tags).to include('import "panda/core/application"')
    end
  end

  describe "#panda_core_stylesheet" do
    before do
      allow(Panda::Core::AssetLoader).to receive(:css_url).and_return("/panda-core-assets/core.css")
    end

    it "returns a stylesheet link tag" do
      result = helper.panda_core_stylesheet
      expect(result).to include("panda-core-assets/core.css")
    end
  end
end
