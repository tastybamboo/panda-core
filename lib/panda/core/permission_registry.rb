# frozen_string_literal: true

module Panda
  module Core
    # Registry for controller-level permission requirements.
    #
    # Gems and host apps register which permissions are needed for each
    # controller action. The {AdminAuthorization} concern reads this registry
    # at request time to enforce access control.
    #
    # == Usage
    #
    #   # In a gem engine (config.to_prepare or initializer):
    #   Panda::Core::PermissionRegistry.register(
    #     "Panda::CMS::Admin::PagesController",
    #     index: :edit_content,
    #     edit: :edit_content,
    #     destroy: :delete_content
    #   )
    #
    #   # In a host app initializer:
    #   Panda::Core::PermissionRegistry.register(
    #     "Admin::HealthcareProvidersController",
    #     index: :manage_providers,
    #     destroy: :manage_providers
    #   )
    #
    # Actions not registered are allowed for any authenticated admin user.
    # Controllers not registered are also allowed (open by default).
    #
    # == How enforcement works
    #
    # The {AdminAuthorization} concern calls {.permission_for} to look up
    # the required permission, then delegates to +authorize!+ (from
    # {Authorizable}) which checks +config.authorization_policy+.
    #
    # Without panda-cms-pro, the default policy is +user.admin?+ — so only
    # admins pass permission checks. With Pro loaded, the policy uses the
    # role system, allowing non-admin users with the right permissions.
    class PermissionRegistry
      class << self
        # Register permission requirements for a controller.
        #
        # Merges with any previously registered permissions for the same
        # controller, so multiple gems can contribute to the same controller.
        #
        # @param controller_name [String] Fully-qualified controller class name
        # @param permissions [Hash{Symbol => Symbol}] action → permission_key mapping
        def register(controller_name, **permissions)
          registry[controller_name] = (registry[controller_name] || {}).merge(permissions)
        end

        # Look up the required permission for a specific controller action.
        #
        # @param controller_name [String] Fully-qualified controller class name
        # @param action [Symbol] The controller action name
        # @return [Symbol, nil] The required permission key, or nil if not registered
        def permission_for(controller_name, action)
          registry.dig(controller_name, action)
        end

        # Return all registered permissions for a controller.
        #
        # @param controller_name [String] Fully-qualified controller class name
        # @return [Hash{Symbol => Symbol}, nil] action → permission_key mapping
        def permissions_for(controller_name)
          registry[controller_name]
        end

        # Return the full registry (deep copy).
        # @return [Hash]
        def all
          registry.transform_values(&:dup)
        end

        # Clear all registrations (for test isolation).
        def reset!
          @registry = {}
        end

        private

        def registry
          @registry ||= {}
        end
      end
    end
  end
end
