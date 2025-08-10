# frozen_string_literal: true

module Panda
  module Core
    module Subscribers
      # Example subscriber for authentication events
      #
      # To enable in your application, add to an initializer:
      #   Panda::Core::Subscribers::AuthenticationSubscriber.attach
      class AuthenticationSubscriber
        class << self
          def attach
            # Subscribe to user creation
            ActiveSupport::Notifications.subscribe("panda.core.user_created") do |event|
              user = event.payload[:user]
              provider = event.payload[:provider]

              Rails.logger.info "[AuthSubscriber] New user created: #{user.email} via #{provider}"

              # Example: Send welcome email
              # UserMailer.welcome(user).deliver_later if defined?(UserMailer)

              # Example: Track analytics
              # Analytics.track("User Signup", user_id: user.id, provider: provider) if defined?(Analytics)
            end

            # Subscribe to user login
            ActiveSupport::Notifications.subscribe("panda.core.user_login") do |event|
              user = event.payload[:user]
              provider = event.payload[:provider]

              Rails.logger.info "[AuthSubscriber] User logged in: #{user.email} via #{provider}"

              # Example: Update last login time
              # user.touch(:last_login_at) if user.respond_to?(:last_login_at)

              # Example: Track analytics
              # Analytics.track("User Login", user_id: user.id, provider: provider) if defined?(Analytics)
            end

            # Subscribe to user logout
            ActiveSupport::Notifications.subscribe("panda.core.user_logout") do |event|
              user = event.payload[:user]

              Rails.logger.info "[AuthSubscriber] User logged out: #{user.email}"

              # Example: Clean up session data
              # SessionCleanupJob.perform_later(user.id) if defined?(SessionCleanupJob)
            end
          end

          def detach
            ActiveSupport::Notifications.unsubscribe("panda.core.user_created")
            ActiveSupport::Notifications.unsubscribe("panda.core.user_login")
            ActiveSupport::Notifications.unsubscribe("panda.core.user_logout")
          end
        end
      end
    end
  end
end
