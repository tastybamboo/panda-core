# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Test-only controller for setting up authentication in system tests
      # This bypasses OAuth to avoid cross-process issues with Capybara
      # Security: This route is only defined in test environments, never in production
      #
      # Usage in tests:
      #   post "/admin/test_sessions", params: { user_id: user.id }
      #   post "/admin/test_sessions", params: { user_id: user.id, return_to: "/some/path" }
      class TestSessionsController < ActionController::Base
        # Skip CSRF protection for test-only endpoint
        skip_before_action :verify_authenticity_token, raise: false

        def create
          user = Panda::Core::User.find(params[:user_id])

          # Check if user is admin (mimics real OAuth behavior)
          unless user.admin?
            # Non-admin users are redirected to login with error (mimics real OAuth flow)
            flash[:alert] = "You do not have permission to access the admin area."
            # Keep flash for one more request to survive redirect in tests
            flash.keep(:alert) if Rails.env.test?
            redirect_to admin_login_path, allow_other_host: false, status: :found
            return
          end

          # Set session (mimics real OAuth callback)
          session[:user_id] = user.id
          Panda::Core::Current.user = user

          # Support custom redirect path for test flexibility
          redirect_path = params[:return_to] || determine_default_redirect_path
          redirect_to redirect_path, allow_other_host: false, status: :found
        rescue ActiveRecord::RecordNotFound
          render html: "User not found: #{params[:user_id]}", status: :not_found
        rescue => e
          render html: "Error: #{e.class} - #{e.message}<br>#{e.backtrace.first(5).join('<br>')}", status: :internal_server_error
        end

        private

        def determine_default_redirect_path
          # Use configured dashboard path if available, otherwise default to admin root
          if Panda::Core.config.dashboard_redirect_path
            path = Panda::Core.config.dashboard_redirect_path
            path.respond_to?(:call) ? path.call : path
          else
            admin_root_path
          end
        end
      end
    end
  end
end
