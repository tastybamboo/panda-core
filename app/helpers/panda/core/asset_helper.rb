# frozen_string_literal: true

module Panda
  module Core
    module AssetHelper
      # Include Panda Core JavaScript and CSS assets
      def panda_core_assets
        Panda::Core::AssetLoader.asset_tags.html_safe
      end

      # Include only Core JavaScript
      def panda_core_javascript
        # Use asset_tags for development mode (importmap) compatibility
        # In development, this will use importmap; in production/test, compiled bundles
        if Panda::Core::AssetLoader.use_github_assets?
          js_url = Panda::Core::AssetLoader.javascript_url
          return "" unless js_url

          if js_url.start_with?("/panda-core-assets/")
            javascript_include_tag(js_url)
          else
            javascript_include_tag(js_url, type: "module")
          end
        else
          # Development mode - Use the engine's importmap (loaded in initializer)
          # This keeps the engine's JavaScript separate from the app's importmap
          # Build the importmap JSON manually since paths are already absolute
          imports = {}
          Panda::Core.importmap.instance_variable_get(:@packages).each do |name, package|
            imports[name] = package.path
          end

          importmap_json = JSON.generate({"imports" => imports})

          <<~HTML.html_safe
            <script type="importmap">#{importmap_json}</script>
            <script type="module">import "panda/core/application"</script>
            <script type="module">import "panda/core/controllers/index"</script>
          HTML
        end
      end

      # Include only Core CSS
      def panda_core_stylesheet
        css_url = Panda::Core::AssetLoader.css_url
        return "" unless css_url

        stylesheet_link_tag(css_url)
      end
    end
  end
end
