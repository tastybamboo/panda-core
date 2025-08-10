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
        js_url = Panda::Core::AssetLoader.javascript_url
        return "" unless js_url
        
        if js_url.start_with?("/panda-core-assets/")
          javascript_include_tag(js_url)
        else
          javascript_include_tag(js_url, type: "module")
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