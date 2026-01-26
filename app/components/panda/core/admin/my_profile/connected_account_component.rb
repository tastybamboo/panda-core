# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module MyProfile
        class ConnectedAccountComponent < Panda::Core::Base
          def initialize(provider:, user:)
            @provider = provider
            @user = user
            @provider_info = Panda::Core::OAuthProviders.info(provider)
            # TODO: Track which provider user logged in with
            # For now, we don't track the provider, so we can't show connection status
            @is_connected = user.respond_to?(:oauth_provider) && user.oauth_provider == provider.to_s
            super()
          end

          def provider_info
            @provider_info
          end

          def connected?
            @is_connected
          end
        end
      end
    end
  end
end
