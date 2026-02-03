# Authorization

Panda Core provides a pluggable authorization layer that allows downstream gems to inject permission checks into the admin interface.

## Overview

By default, only users with `admin? == true` can access the admin panel. The authorization system extends this by allowing a configurable **authorization policy** that can grant access to non-admin users based on roles, permissions, or any custom logic.

## Architecture

```
┌─────────────────────────────────────────────┐
│ Panda::Core::Admin::BaseController          │
│   includes Panda::Core::Authorizable        │
│                                             │
│   authenticate_admin_user!                  │
│     → user_signed_in?                       │
│     → authorized_for_admin_access?          │
│         → admin? (bypass)                   │
│         → authorization_policy(:access_admin)│
└─────────────────────────────────────────────┘
         ↓ delegated to
┌─────────────────────────────────────────────┐
│ Panda::Core.config.authorization_policy     │
│   ->(user, action, resource) { ... }        │
│                                             │
│   Default: user.admin?                      │
│   Pro:     role-based permission checks     │
└─────────────────────────────────────────────┘
```

## The Authorizable Concern

`Panda::Core::Authorizable` is included in `Panda::Core::Admin::BaseController` and provides:

### `authorized_for?(action, resource = nil)`

Checks whether the current user is authorized for the given action. Admin users bypass all checks. For non-admin users, delegates to `Panda::Core.config.authorization_policy`.

### `authorize!(action, resource = nil)`

Calls `authorized_for?` and renders a 403/redirect if the user is not authorized. Use this in controller actions for manual permission checks.

### `can?(action, resource = nil)`

View-layer helper (exposed via `helper_method`) for checking permissions in templates:

```erb
<% if can?(:edit_content) %>
  <%= link_to "Edit", edit_page_path(@page) %>
<% end %>
```

### `authorized_for_admin_access?`

Checks whether the current user is authorized to access the admin panel at all. Used by `authenticate_admin_user!`.

### `require_permission` (class method DSL)

Declarative permission checks on controller actions:

```ruby
class MyController < Panda::Core::Admin::BaseController
  require_permission :edit_content, only: [:edit, :update]
  require_permission :delete_content, only: [:destroy]
end
```

## Configuring the Authorization Policy

The authorization policy is a lambda that receives `(user, action, resource)` and returns a boolean:

```ruby
Panda::Core.configure do |config|
  config.authorization_policy = ->(user, action, resource) {
    case action
    when :access_admin
      user.has_any_role?
    else
      user.has_permission?(action)
    end
  }
end
```

### Default Policy

The default policy simply checks `user.admin?`:

```ruby
config.authorization_policy = ->(user, action, resource) { user.admin? }
```

### With Panda CMS Pro

When panda-cms-pro is loaded, it automatically sets the authorization policy to support role-based access:

- `:access_admin` — returns `true` if the user has any active role assignment
- Other actions — delegates to `user.has_permission?(action)` which checks all of the user's role assignments

## Session Controller Integration

The sessions controller (`Panda::Core::Admin::SessionsController`) also respects the authorization policy during login. When a user authenticates via OAuth, the controller checks:

1. Is the user an admin? → Allow login
2. Does the authorization policy grant `:access_admin`? → Allow login
3. Neither → Reject with "You do not have permission to access the admin area"

This ensures that non-admin users with roles can log in, while users with no roles are still blocked.
