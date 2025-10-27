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

      # Returns the FontAwesome icon name for a given provider
      # Checks provider config first, then falls back to the mapping, then uses the provider name as-is
      def oauth_provider_icon(provider)
        provider_config = Panda::Core.configuration.authentication_providers[provider]
        provider_config&.dig(:icon) || PROVIDER_ICON_MAP[provider.to_sym] || provider.to_s
      end
    end
  end
end
