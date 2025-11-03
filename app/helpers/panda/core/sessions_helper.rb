# frozen_string_literal: true

module Panda
  module Core
    module SessionsHelper
      # Map OAuth provider names to their FontAwesome icon names
      PROVIDER_ICON_MAP = {
        google_oauth2: "google",
        microsoft_graph: "microsoft",
        github: "github"
      }.freeze

      # Map of providers that don't use fa-brands (use fa-solid instead)
      PROVIDER_NON_BRAND_ICONS = {
        developer: "code"
      }.freeze

      # Map OAuth provider names to their display names
      PROVIDER_NAME_MAP = {
        google_oauth2: "Google",
        microsoft_graph: "Microsoft",
        github: "GitHub",
        developer: "Developer"
      }.freeze

      # Returns the FontAwesome icon name for a given provider
      # Checks provider config first, then falls back to the mapping, then uses the provider name as-is
      def oauth_provider_icon(provider)
        provider_config = Panda::Core.config.authentication_providers[provider]
        provider_config&.dig(:icon) || PROVIDER_ICON_MAP[provider.to_sym] || PROVIDER_NON_BRAND_ICONS[provider.to_sym] || provider.to_s
      end

      # Returns true if the provider uses a non-brand icon (fa-solid, fa-regular, etc.)
      def oauth_provider_non_brand?(provider)
        PROVIDER_NON_BRAND_ICONS.key?(provider.to_sym)
      end

      # Returns the display name for a given provider
      # Checks provider config first, then falls back to the mapping, then humanizes the provider name
      def oauth_provider_name(provider, provider_config = nil)
        provider_config ||= Panda::Core.config.authentication_providers[provider]
        provider_config&.dig(:name) || PROVIDER_NAME_MAP[provider.to_sym] || provider.to_s.humanize
      end
    end
  end
end
