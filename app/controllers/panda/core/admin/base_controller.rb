# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Base controller for all admin interfaces across Panda gems
      # Provides authentication, helpers, and hooks for extending functionality
      class BaseController < ::ActionController::Base
        include Panda::Core::Authorizable

        layout "panda/core/admin"

        protect_from_forgery with: :exception

        default_form_builder Panda::Core::FormBuilder

        # Add flash types for improved alert support with Tailwind
        add_flash_types :success, :warning, :error, :info

        # Include helper modules
        helper Panda::Core::SessionsHelper
        helper Panda::Core::AssetHelper if defined?(Panda::Core::AssetHelper)

        before_action :set_current_request_details
        before_action :authenticate_admin_user!

        helper_method :breadcrumbs
        helper_method :current_user
        helper_method :user_signed_in?

        def breadcrumbs
          @breadcrumbs ||= []
        end

        def add_breadcrumb(name, path = nil)
          breadcrumbs << Breadcrumb.new(name, path)
        end

        # Set the current request details
        # @return [void]
        def set_current_request_details
          # Set Core current attributes
          Panda::Core::Current.request_id = request.uuid
          Panda::Core::Current.user_agent = request.user_agent
          Panda::Core::Current.ip_address = request.ip
          Panda::Core::Current.root = request.base_url
          Panda::Core::Current.user ||= Panda::Core::User.find_by(id: session[Panda::Core::ADMIN_SESSION_KEY]) if session[Panda::Core::ADMIN_SESSION_KEY]

          track_session_activity if Panda::Core::Current.user
        end

        def authenticate_user!
          redirect_to main_app.root_path, flash: {error: "Please login to view this!"} unless user_signed_in?
        end

        def authenticate_admin_user!
          unless user_signed_in?
            redirect_to panda_core.admin_login_path,
              flash: {error: "Please login to view this!"}
            return
          end

          return if authorized_for_admin_access?

          redirect_to panda_core.admin_login_path,
            flash: {error: "You are not authorized to access the admin area."}
        end

        # Required for paper_trail and seems as good as convention these days
        def current_user
          Panda::Core::Current.user
        end

        def user_signed_in?
          !!Panda::Core::Current.user
        end

        private

        def track_session_activity
          return unless session.id.present?

          last_tracked = session[:_session_tracked_at]
          return if last_tracked && Time.current.to_i - last_tracked < 60

          begin
            Panda::Core::UserSession.find_or_create_by(
              session_id: session.id.to_s,
              user: Panda::Core::Current.user
            ) do |us|
              us.ip_address = request.remote_ip
              us.user_agent = request.user_agent
            end
            Panda::Core::UserSession.where(
              session_id: session.id.to_s,
              user: Panda::Core::Current.user
            ).update_all(
              last_active_at: Time.current,
              active: true
            )
            session[:_session_tracked_at] = Time.current.to_i
          rescue ActiveRecord::RecordNotUnique => e
            Rails.logger.debug("Session already exists: #{e.message}")
          rescue => e
            Rails.logger.debug("Session tracking skipped: #{e.message}")
          end
        end
      end
    end
  end
end
