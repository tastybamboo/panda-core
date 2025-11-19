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
        expect(result).to include("https://esm.sh/cropperjs@1.6.2")
      end

      it "includes tailwindplus/elements from the importmap" do
        result = helper.panda_core_javascript
        expect(result).to include('"@tailwindplus/elements"')
        expect(result).to include("https://esm.sh/@tailwindplus/elements@1")
      end

      it "includes correct file paths with .js extension for local modules" do
        result = helper.panda_core_javascript
        expect(result).to include('"/panda/core/application.js"')
        expect(result).to include('"/panda/core/controllers/index.js"')
        expect(result).to include('"/panda/core/controllers/toggle_controller.js"')
        expect(result).not_to include('"/panda/core/application"') # Should not be missing .js
      end

      # Test to ensure inline importmap stays in sync with config/importmap.rb
      it "includes all CDN packages from config/importmap.rb" do
        # Read the importmap config file
        importmap_config = File.read(Panda::Core::Engine.root.join("config/importmap.rb"))

        # Extract CDN packages (those pinned to https:// URLs)
        cdn_packages = []
        importmap_config.scan(/pin\s+"([^"]+)",\s+to:\s+"(https:\/\/[^"]+)"/) do |package, url|
          cdn_packages << {package: package, url: url}
        end

        result = helper.panda_core_javascript

        # Verify each CDN package is in the inline importmap
        cdn_packages.each do |pkg|
          expect(result).to include(%("#{pkg[:package]}": "#{pkg[:url]}"))
            .or(include(%("#{pkg[:package]}":"#{pkg[:url]}")))
            .or(include(%("#{pkg[:package]}": "#{pkg[:url].split("@").first}@))),
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
