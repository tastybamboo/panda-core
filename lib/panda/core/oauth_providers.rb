module Panda
  module Core
    module OAuthProviders
      # Provider metadata for display purposes
      PROVIDER_INFO = {
        microsoft_graph: {
          name: "Microsoft",
          icon: "fa-brands fa-microsoft",
          color: "#00a4ef"
        },
        google_oauth2: {
          name: "Google",
          icon: "fa-brands fa-google",
          color: "#4285f4"
        },
        github: {
          name: "GitHub",
          icon: "fa-brands fa-github",
          color: "#333"
        }
      }.freeze

      def self.setup
        providers = []

        begin
          require "omniauth/strategies/github"
          providers << :github
        rescue LoadError
          # GitHub OAuth functionality not available
        end

        begin
          require "omniauth/strategies/google_oauth2"
          providers << :google_oauth2
        rescue LoadError
          # Google OAuth functionality not available
        end

        begin
          require "omniauth/strategies/microsoft_graph"
          providers << :microsoft_graph
        rescue LoadError
          # Microsoft OAuth functionality not available
        end

        providers
      end

      def self.info(provider)
        PROVIDER_INFO[provider.to_sym] || {
          name: provider.to_s.titleize,
          icon: "fa-solid fa-circle-user",
          color: "#6b7280"
        }
      end
    end
  end
end
