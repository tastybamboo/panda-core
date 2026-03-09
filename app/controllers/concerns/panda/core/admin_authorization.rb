# frozen_string_literal: true

module Panda
  module Core
    # Automatic permission enforcement for admin controllers.
    #
    # Reads from {PermissionRegistry} to determine which permission is required
    # for the current controller action, then delegates to +authorize!+ (from
    # {Authorizable}) to check the configured +authorization_policy+.
    #
    # This concern is included in {Admin::BaseController} so all admin
    # controllers automatically get permission enforcement. No per-controller
    # configuration is needed — just register permissions in the registry.
    #
    # Admin users (+user.admin?+) bypass all checks via {Authorizable#authorize!}.
    #
    # == Behavior for unmapped controllers/actions
    #
    # * Controller not in registry → access allowed (open by default)
    # * Action not in registry → access allowed
    # * Action mapped → +authorize!(permission_key)+ is called
    #
    # == Example
    #
    #   # Register permissions (in an engine or initializer):
    #   Panda::Core::PermissionRegistry.register(
    #     "Panda::CMS::Admin::PagesController",
    #     index: :edit_content, destroy: :delete_content
    #   )
    #
    #   # Enforcement happens automatically via before_action
    module AdminAuthorization
      extend ActiveSupport::Concern

      included do
        before_action :enforce_registry_permissions!
      end

      private

      def enforce_registry_permissions!
        # Admin users bypass all checks (handled by authorize! but skip lookup too)
        return if current_user&.admin?

        required_permission = Panda::Core::PermissionRegistry.permission_for(
          self.class.name,
          action_name.to_sym
        )

        # No registration = allowed
        return unless required_permission

        # Delegate to Authorizable#authorize! which checks authorization_policy
        authorize!(required_permission)
      end
    end
  end
end
