# frozen_string_literal: true

module Panda
  module Core
    # Authorizable concern for admin controllers.
    #
    # Provides a generic authorization layer that delegates permission checks
    # to the configurable `Panda::Core.config.authorization_policy` lambda.
    # This allows downstream gems (e.g. panda-cms-pro) to inject RBAC checks
    # without panda-core needing any knowledge of roles or permissions.
    #
    # Usage in controllers:
    #
    #   class PagesController < Admin::BaseController
    #     require_permission :edit_content, only: [:edit, :update]
    #     require_permission :publish_content, only: [:publish]
    #   end
    #
    # Or manually:
    #
    #   def update
    #     authorize!(:edit_content, @page)
    #   end
    #
    module Authorizable
      extend ActiveSupport::Concern

      included do
        helper_method :can? if respond_to?(:helper_method)
      end

      class_methods do
        # DSL for declarative permission checks.
        # Registers a before_action that calls authorize! for the given permission.
        #
        # @param permission [Symbol] the permission key to check
        # @param options [Hash] standard before_action options (only:, except:, etc.)
        def require_permission(permission, **options)
          before_action(**options) do
            authorize!(permission)
          end
        end
      end

      # Check whether the current user is authorized for the given action.
      #
      # @param action [Symbol] the action/permission to check
      # @param resource [Object, nil] optional resource context
      # @return [Boolean]
      def authorized_for?(action, resource = nil)
        return false unless current_user

        # Admin users bypass all authorization checks
        return true if current_user.admin?

        # Delegate to the configured authorization policy
        policy = Panda::Core.config.authorization_policy
        policy.call(current_user, action, resource)
      end

      # Authorize the current user or render a 403/redirect.
      #
      # @param action [Symbol] the action/permission to check
      # @param resource [Object, nil] optional resource context
      # @raise renders 403 or redirects if not authorized
      def authorize!(action, resource = nil)
        return if authorized_for?(action, resource)

        respond_to do |format|
          format.html do
            flash[:error] = "You do not have permission to perform this action."
            redirect_to(request.referer || panda_core.admin_root_path)
          end
          format.json do
            render json: {error: "Forbidden", status: 403}, status: :forbidden
          end
        end
      end

      # View-layer helper for checking permissions.
      # Can be used in templates: `if can?(:edit_content)`
      #
      # @param action [Symbol] the action/permission to check
      # @param resource [Object, nil] optional resource context
      # @return [Boolean]
      def can?(action, resource = nil)
        authorized_for?(action, resource)
      end

      # Check whether the current user is authorized to access the admin panel.
      # This is called during authentication to allow non-admin users with roles
      # to access the admin area.
      #
      # @return [Boolean]
      def authorized_for_admin_access?
        return false unless current_user

        # Admin users always have access
        return true if current_user.admin?

        # Check the authorization policy for :access_admin
        policy = Panda::Core.config.authorization_policy
        policy.call(current_user, :access_admin, nil)
      end
    end
  end
end
