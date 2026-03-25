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
        expect(result).to include('<script type="importmap">')
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
        expect(result).to include('<script type="importmap">')
        expect(result).to include('"panda/core/application"')
      end
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
