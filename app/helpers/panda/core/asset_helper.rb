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
      #
      # Note: Always uses importmap (Rails 8 approach), regardless of asset source
      #
      # The tags are built by hand rather than through +javascript_importmap_tags+
      # because the importmap is assembled from ModuleRegistry rather than from a
      # Rails importmap. That means the nonce has to be applied by hand too: under
      # a Content Security Policy of +script-src 'self'+ an un-nonced inline
      # <script> is dropped silently, which takes Turbo and every Stimulus
      # controller with it and looks like nothing at all.
      def panda_core_javascript
        panda_core_importmap_tag + panda_core_script_tags
      end

      # The <script type="importmap"> tag on its own.
      #
      # Split out from the entry points because a host app that emits its own
      # importmap needs exactly one: browsers with native import-map support
      # honour only the first one in the document and ignore the rest. Such an
      # app should merge Panda's pins (Panda::Core::ModuleRegistry.combined_importmap)
      # into its own importmap and call panda_core_script_tags instead of
      # panda_core_javascript.
      def panda_core_importmap_tag
        imports = Panda::Core::ModuleRegistry.combined_importmap
        importmap_json = JSON.generate({"imports" => imports})

        %(<script type="importmap"#{panda_core_nonce_attribute}>#{importmap_json}</script>).html_safe
      end

      # The module entry-point <script> tags for Core and every registered module,
      # without an importmap. Safe to call alongside a host app's own importmap.
      def panda_core_script_tags
        nonce_attr = panda_core_nonce_attribute
        entry_points = []

        Panda::Core::ModuleRegistry.modules.each do |gem_name, info|
          # Extract module namespace from gem name (e.g., "panda-cms" -> "cms")
          module_slug = gem_name.sub(/^panda-/, "")

          # Check if the module is actually loaded
          module_name = info[:engine].sub(/::Engine$/, "")
          next unless Object.const_defined?(module_name)

          entry_points << %(<script type="module"#{nonce_attr}>import "panda/#{module_slug}/application"</script>)
          entry_points << %(<script type="module"#{nonce_attr}>import "panda/#{module_slug}/controllers/index"</script>)
        end

        entry_points.join("\n").html_safe
      end

      # Include only Core CSS
      def panda_core_stylesheet
        css_url = Panda::Core::AssetLoader.css_url
        return "" unless css_url

        stylesheet_link_tag(css_url)
      end

      private

      # A ready-to-interpolate ` nonce="..."` attribute, or "" when there is no
      # nonce to emit.
      #
      # Guarded on presence because an app with no CSP configured gets nil back,
      # and emitting nonce="" there is worse than emitting nothing: an empty
      # nonce never matches a policy, so it would break the very apps that have
      # no CSP problem to begin with.
      def panda_core_nonce_attribute
        nonce = panda_core_csp_nonce
        return "" if nonce.blank?

        %( nonce="#{ERB::Util.html_escape(nonce)}")
      end

      def panda_core_csp_nonce
        return nil unless respond_to?(:content_security_policy_nonce)

        content_security_policy_nonce
      rescue
        # No request in scope (e.g. rendering outside a controller), so there is
        # no per-request nonce to read.
        nil
      end
    end
  end
end
