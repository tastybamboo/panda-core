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
          # Development mode - Load JavaScript with import map
          # Files are served by Rack::Static middleware from engine's app/javascript
          importmap_html = <<~HTML
            <script type="importmap">
              {
                "imports": {
                  "@hotwired/stimulus": "/panda/core/vendor/@hotwired--stimulus.js",
                  "@hotwired/turbo": "/panda/core/vendor/@hotwired--turbo.js",
                  "@rails/actioncable/src": "/panda/core/vendor/@rails--actioncable--src.js",
                  "tailwindcss-stimulus-components": "/panda/core/tailwindcss-stimulus-components.js",
                  "@fortawesome/fontawesome-free": "https://ga.jspm.io/npm:@fortawesome/fontawesome-free@7.1.0/js/all.js",
                  "panda/core/application": "/panda/core/application.js",
                  "panda/core/controllers/toggle_controller": "/panda/core/controllers/toggle_controller.js",
                  "panda/core/controllers/theme_form_controller": "/panda/core/controllers/theme_form_controller.js"
                }
              }
            </script>
            <script type="module" src="/panda/core/application.js"></script>
            <script type="module" src="/panda/core/controllers/index.js"></script>
          HTML
          importmap_html.html_safe
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
