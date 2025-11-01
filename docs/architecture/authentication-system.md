# Authentication System Architecture

This document describes the Panda Core authentication system architecture and how it's used across Panda gems.

## Overview

Panda Core provides a complete OAuth-based authentication system that other Panda gems can depend on. The system includes:

- **OAuth Integration**: Google, GitHub, and Microsoft Graph providers
- **User Management**: User model with admin roles
- **Session Management**: Redis-backed sessions for cross-process support
- **Test Infrastructure**: Comprehensive test helpers for all test types
- **Flash Messages**: Proper handling across redirects

## Architecture

### Core Components

#### 1. User Model (`Panda::Core::User`)

Located in: `app/models/panda/core/user.rb`

The User model is the central authentication entity:

```ruby
class Panda::Core::User < ApplicationRecord
  # OAuth fields
  attribute :email
  attribute :firstname
  attribute :lastname
  attribute :admin, :boolean, default: false

  # OAuth integration
  def self.find_or_create_from_auth_hash(auth_hash)
    # Auto-provision users from OAuth callbacks
  end

  def admin?
    admin
  end
end
```

#### 2. Sessions Controller (`Panda::Core::Admin::SessionsController`)

Located in: `app/controllers/panda/core/admin/sessions_controller.rb`

Handles OAuth callbacks and session management:

- `new` - Login page with provider buttons
- `create` - OAuth callback handler
- `failure` - OAuth failure handler
- `destroy` - Logout

**Key Features**:
- Admin-only access enforcement
- Flash messages with `flash.keep` in test environment
- Configurable dashboard redirect
- Provider path name override support

#### 3. Test Sessions Controller (`Panda::Core::Admin::TestSessionsController`)

Located in: `app/controllers/panda/core/admin/test_sessions_controller.rb`

**Test-only controller** for bypassing OAuth in tests:

```ruby
# Only available in test environment
get "/admin/test_login/:user_id", to: "admin/test_sessions#create"
post "/admin/test_sessions", to: "admin/test_sessions#create"
```

**Security**: Routes only registered when `Rails.env.test? == true`.

#### 4. Current Attributes (`Panda::Core::Current`)

Located in: `app/models/panda/core/current.rb`

Thread-safe request-scoped user storage:

```ruby
Panda::Core::Current.user = user      # Set current user
current_user = Panda::Core::Current.user  # Get current user
```

#### 5. Admin Constraint (`Panda::Core::AdminConstraint`)

Located in: `lib/panda/core/admin_constraint.rb`

Route constraint for protecting admin routes:

```ruby
constraints Panda::Core::AdminConstraint.new(&:present?) do
  # Protected admin routes
end
```

### Configuration

#### OAuth Providers

Located in: `lib/panda/core.rb`

```ruby
Panda::Core.configure do |config|
  config.authentication_providers = {
    google_oauth2: {
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"]
    },
    github: {
      client_id: ENV["GITHUB_CLIENT_ID"],
      client_secret: ENV["GITHUB_CLIENT_SECRET"],
      scope: "user:email"
    },
    microsoft_graph: {
      client_id: ENV["MICROSOFT_CLIENT_ID"],
      client_secret: ENV["MICROSOFT_CLIENT_SECRET"]
    }
  }

  # Where to redirect after successful login
  config.dashboard_redirect_path = "/admin"  # or a proc

  # Admin path prefix
  config.admin_path = "/admin"
end
```

#### Session Storage

For cross-process testing support, use Redis:

```ruby
# config/environments/test.rb
config.session_store :redis_store, {
  servers: ["redis://localhost:6379/1/session"],
  expire_after: 90.minutes,
  key: "_your_app_session_test"
}
```

## Test Infrastructure

### Test Helpers Location

`spec/support/authentication_test_helpers.rb`

Automatically included in request, system, and controller specs when you load Panda Core's support files.

### Helper Categories

**User Creation**:
- `create_admin_user(attributes = {})`
- `create_regular_user(attributes = {})`
- `admin_user` - Memoized admin
- `regular_user` - Memoized regular user

**OAuth Mocking**:
- `clear_omniauth_config`
- `mock_oauth_for_user(user, provider:)`

**Request Specs**:
- `sign_in_as(user)` - Direct session manipulation

**System Specs**:
- `login_with_test_endpoint(user, return_to:, expect_success:)`
- `login_with_google(user, expect_success:)`
- `login_with_github(user, expect_success:)`
- `login_with_microsoft(user, expect_success:)`
- `login_as_admin(attributes = {})`

### Test Types and Recommendations

| Test Type | When to Use | Flash Testing | Speed |
|-----------|-------------|---------------|-------|
| **Request Spec** | Authentication logic, flash messages, API endpoints | ✅ Yes | Fast |
| **System Spec** | Full user workflows, JavaScript interactions | ❌ No | Slow |
| **Controller Spec** | Controller-specific logic (legacy) | ⚠️ Limited | Fast |

**Golden Rule**: Test flash messages in **request specs**, not system specs.

## Flash Message Handling

### The Challenge

Flash messages in Rails persist for exactly one request, then are cleared. In cross-process testing (system tests with Cuprite), timing issues prevent reliable flash testing.

### The Solution

1. **Request Specs**: Test flash directly before rendering
```ruby
post "/admin/test_sessions", params: {user_id: invalid_id}
expect(flash[:error]).to eq("User not found")  # ✅ Works
```

2. **flash.keep in Test Environment**: Preserve flash across redirects
```ruby
flash[:error] = "Message"
flash.keep(:error) if Rails.env.test?
redirect_to admin_login_path
```

3. **Layout Rendering**: Ensure layouts render flash
```erb
<%= render "panda/core/admin/shared/flash" %>
```

## Integration with Other Gems

### For Panda CMS (Example)

#### 1. Gemfile Dependency

```ruby
gem "panda-core", "~> 1.0"
```

#### 2. Load Test Helpers

```ruby
# cms/spec/rails_helper.rb
panda_core_support_path = Gem.loaded_specs["panda-core"]&.full_gem_path
if panda_core_support_path
  Dir[File.join(panda_core_support_path, "spec/support/**/*.rb")].sort.each { |f| require f }
end
```

#### 3. Use Authentication in Tests

```ruby
RSpec.describe "CMS Pages", type: :request do
  before { sign_in_as(create_admin_user) }

  it "allows admin to manage pages" do
    get "/admin/cms/pages"
    expect(response).to have_http_status(:success)
  end
end
```

#### 4. Protect Routes with Constraint

```ruby
# cms/config/routes.rb
Panda::CMS::Engine.routes.draw do
  constraints Panda::Core::AdminConstraint.new(&:present?) do
    namespace :admin do
      resources :pages
      resources :posts
    end
  end
end
```

## Migration History

### Pre-Migration (Before v0.8.0)

- Authentication logic duplicated in panda-cms
- Test helpers scattered across CMS
- No shared infrastructure for other gems

### Post-Migration (v0.8.0+)

**Moved to Panda Core**:
- ✅ `Panda::Core::Admin::TestSessionsController`
- ✅ Authentication test helpers
- ✅ OAuth configuration
- ✅ Session management
- ✅ Flash message handling
- ✅ Request specs for authentication
- ✅ System specs for authentication

**Removed from Panda CMS**:
- ❌ `Panda::CMS::Admin::TestSessionsController` (moved to core)
- ❌ Duplicate user helpers (moved to core)
- ❌ Duplicate OAuth helpers (moved to core)
- ❌ Authentication request specs (moved to core)

**Benefits**:
- 🎯 Single source of truth for authentication
- 🎯 Reusable across all Panda gems
- 🎯 Centralized security updates
- 🎯 Comprehensive test infrastructure
- 🎯 Flash message testing that works

## Architectural Principles

1. **Separation of Concerns**: Authentication lives in Core, content management in CMS
2. **Test-Driven**: Comprehensive test helpers for all test types
3. **Security First**: Test endpoints only in test environment
4. **DRY**: No duplication across gems
5. **Extensibility**: Easy for new Panda gems to adopt

## Future Enhancements

Potential improvements for future versions:

- [ ] Support for additional OAuth providers (Twitter, Facebook, etc.)
- [ ] Two-factor authentication
- [ ] API token authentication
- [ ] Role-based permissions beyond admin/user
- [ ] Session timeout configuration
- [ ] Remember me functionality
- [ ] Email/password authentication option

## See Also

- [Authentication Test Helpers Guide](../testing/authentication-helpers.md)
- [Flash Message Testing Guide](../../../cms/docs/testing/flash-message-testing.md)
- [OAuth Provider Configuration](../configuration/oauth-providers.md)
- [Session Management](../configuration/sessions.md)

## Support

For questions or issues with the authentication system:
1. Check this documentation
2. Review example specs in `panda-core/spec/requests/panda/core/admin/sessions_spec.rb`
3. Open an issue in the Panda Core repository with the `authentication` label
