# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SessionsController < BaseController
        # Skip authentication for login/logout actions
        skip_before_action :authenticate_admin_user!, only: [:new, :create, :destroy, :failure]

        def new
          @providers = Core.config.authentication_providers.keys
        end

        def create
          auth = request.env["omniauth.auth"]
          provider_path = params[:provider]&.to_sym

          # Find the actual provider key (might be using path_name override)
          provider = find_provider_by_path(provider_path)

          unless provider && Core.config.authentication_providers.key?(provider)
            redirect_to admin_login_path, flash: {error: "Authentication provider not enabled"}
            return
          end

          user = User.find_or_create_from_auth_hash(auth)

          if user.persisted?
            # Check if user is admin before allowing access
            unless user.admin?
              redirect_to admin_login_path, flash: {error: "You do not have permission to access the admin area"}
              return
            end

            session[:user_id] = user.id
            Panda::Core::Current.user = user

            ActiveSupport::Notifications.instrument("panda.core.user_login",
              user: user,
              provider: provider)

            # Use configured dashboard path or default to admin_root_path
            redirect_path = Panda::Core.config.dashboard_redirect_path || admin_root_path
            redirect_path = redirect_path.call if redirect_path.respond_to?(:call)
            redirect_to redirect_path, flash: {success: "Successfully logged in as #{user.name}"}
          else
            redirect_to admin_login_path, flash: {error: "Unable to create account: #{user.errors.full_messages.join(", ")}"}
          end
        rescue => e
          Rails.logger.error "Authentication error: #{e.message}"
          redirect_to admin_login_path, flash: {error: "Authentication failed: #{e.message}"}
        end

        def failure
          message = params[:message] || "Authentication failed"
          strategy = params[:strategy] || "unknown"

          Rails.logger.error "OmniAuth failure: strategy=#{strategy}, message=#{message}"
          redirect_to admin_login_path, flash: {error: "Authentication failed: #{message}"}
        end

        def destroy
          session.delete(:user_id)
          Panda::Core::Current.user = nil

          ActiveSupport::Notifications.instrument("panda.core.user_logout")

          redirect_to admin_login_path, flash: {success: "Successfully logged out"}
        end

        private

        # Find the provider key by path name (handles path_name override)
        def find_provider_by_path(provider_path)
          # First check if it's a direct match
          return provider_path if Core.config.authentication_providers.key?(provider_path)

          # Then check if any provider has a matching path_name
          Core.config.authentication_providers.each do |key, config|
            return key if config[:path_name]&.to_sym == provider_path
          end

          nil
        end
      end
    end
  end
end
