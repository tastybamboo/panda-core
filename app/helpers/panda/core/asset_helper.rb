# frozen_string_literal: true

module Panda
  module Core
    module AssetHelper
      # Include Panda Core JavaScript and CSS assets
      def panda_core_assets
        Panda::Core::AssetLoader.asset_tags.html_safe
      end

      # Include only Core JavaScript
      #
      # This is the single entry point for all Panda JavaScript loading.
      # It automatically includes JavaScript from Core and all registered modules
      # via ModuleRegistry.
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
          # Development mode - Use ModuleRegistry to combine all Panda module importmaps
          imports = Panda::Core::ModuleRegistry.combined_importmap

          importmap_json = JSON.generate({"imports" => imports})

          # Generate entry point script tags for all registered modules (including Core)
          entry_points = []

          # Add entry points for each registered module
          Panda::Core::ModuleRegistry.modules.each do |gem_name, info|
            # Extract module namespace from gem name (e.g., "panda-cms" -> "cms")
            module_slug = gem_name.sub(/^panda-/, "")

            # Check if the module is actually loaded
            module_name = info[:engine].sub(/::Engine$/, "")
            next unless Object.const_defined?(module_name)

            entry_points << %(<script type="module">import "panda/#{module_slug}/application"</script>)
            entry_points << %(<script type="module">import "panda/#{module_slug}/controllers/index"</script>)
          end

          <<~HTML.html_safe
            <script type="importmap">#{importmap_json}</script>
            #{entry_points.join("\n")}
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
