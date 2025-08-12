# frozen_string_literal: true

module Panda
  module Core
    module Notifications
      # Event names following Rails convention: namespace.event
      USER_CREATED = "panda.core.user_created"
      USER_LOGIN = "panda.core.user_login"
      USER_LOGOUT = "panda.core.user_logout"
      ADMIN_ACTION = "panda.core.admin_action"

      class << self
        # Subscribe to a Panda Core event
        #
        # @example
        #   Panda::Core::Notifications.subscribe(:user_created) do |event|
        #     UserMailer.welcome(event.payload[:user]).deliver_later
        #   end
        def subscribe(event_name, &block)
          event_key = const_get(event_name.to_s.upcase)
          ActiveSupport::Notifications.subscribe(event_key, &block)
        end

        # Instrument a Panda Core event
        #
        # @example
        #   Panda::Core::Notifications.instrument(:user_created, user: user, provider: provider)
        def instrument(event_name, payload = {})
          event_key = const_get(event_name.to_s.upcase)
          ActiveSupport::Notifications.instrument(event_key, payload)
        end

        # Unsubscribe from a Panda Core event
        def unsubscribe(subscriber)
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end
      end
    end
  end
end
