# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SessionsController < AdminController
        # Skip authentication for login/logout actions
        skip_before_action :authenticate_admin_user!, only: [:new, :create, :destroy]

        def new
          @providers = Core.configuration.authentication_providers.keys
        end

        def create
          auth = request.env["omniauth.auth"]
          provider = params[:provider]&.to_sym

          unless Core.configuration.authentication_providers.key?(provider)
            redirect_to admin_login_path, flash: {error: "Authentication provider not enabled"}
            return
          end

          user = User.find_or_create_from_auth_hash(auth)

          if user.persisted?
            session[:user_id] = user.id
            Panda::Core::Current.user = user

            ActiveSupport::Notifications.instrument("panda.core.user_login",
              user: user,
              provider: provider)

            # Use configured dashboard path or default to admin_root_path
            redirect_path = Panda::Core.configuration.dashboard_redirect_path || admin_root_path
            redirect_to redirect_path, flash: {success: "Successfully logged in as #{user.name}"}
          else
            redirect_to admin_login_path, flash: {error: "Unable to create account: #{user.errors.full_messages.join(", ")}"}
          end
        rescue => e
          Rails.logger.error "Authentication error: #{e.message}"
          redirect_to admin_login_path, flash: {error: "Authentication failed: #{e.message}"}
        end

        def destroy
          session.delete(:user_id)
          Panda::Core::Current.user = nil

          ActiveSupport::Notifications.instrument("panda.core.user_logout")

          redirect_to admin_login_path, flash: {success: "Successfully logged out"}
        end
      end
    end
  end
end
