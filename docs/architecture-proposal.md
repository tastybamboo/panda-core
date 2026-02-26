# Architecture Proposal: panda-core as Ecosystem Foundation

This document captures proposed architectural changes for panda-core. It is a design document, not implementation instructions.

## Recommended Migration from panda-cms

Based on analysis of panda-cms architecture, the following components should be moved to panda-core to establish it as the authentication and admin UI foundation:

### 1. Authentication System (High Priority)

**Components to Move:**
- `Panda::CMS::User` → `Panda::Core::User`
- `Panda::CMS::Current` → `Panda::Core::Current` (CurrentAttributes)
- `Panda::CMS::Admin::SessionsController` → `Panda::Core::Admin::SessionsController`
- `Panda::CMS::AdminConstraint` → `Panda::Core::AdminConstraint`

**Why:** panda-cms currently implements a robust OAuth-only authentication system with support for Microsoft, Google, and GitHub providers. This should be the foundation for all Panda ecosystem gems.

**Benefits:**
- Other panda-* gems get authentication out of the box
- Consistent user management across ecosystem
- Reduced duplication of OAuth integration code
- Centralized security updates

### 2. Admin UI Framework (Medium Priority)

**Components to Move:**
- Base admin layout (`layouts/application.html.erb`)
- Core admin components:
  - `Admin::ContainerComponent` - Layout wrapper
  - `Admin::PanelComponent` - Content panels
  - `Admin::HeadingComponent` - Consistent headings
  - `Admin::ButtonComponent` - Styled buttons
  - `Admin::FlashMessageComponent` - Flash messages
- Base admin routes and constraint protection

**Why:** Provides consistent admin UI foundation that panda-cms and future gems can extend.

### 3. Configuration & OAuth System (High Priority)

**Components to Move:**
- OAuth provider configuration and management
- OmniAuth engine integration
- Authentication provider settings system
- Rails credentials integration for OAuth secrets

**Current panda-cms Authentication Features:**
- OAuth-only authentication (no passwords)
- Support for Microsoft Graph, Google OAuth2, GitHub
- Auto-provisioning of users with configurable admin privileges
- Session-based authentication with Rails sessions
- Route protection via constraints
- Request-scoped user storage via CurrentAttributes

## Proposed Hook System

To maintain panda-core as lightweight while allowing panda-cms and other gems to extend functionality:

### 1. Configuration Hooks
```ruby
Panda::Core.configure do |config|
  config.admin_navigation_items = ->(user) { [] }
  config.admin_dashboard_widgets = ->(user) { [] }
  config.user_attributes = []
  config.user_associations = []
  config.authorization_policy = ->(user, action, resource) { user.admin? }
end
```

### 2. Route Extension Points
```ruby
Panda::Core::Engine.routes.draw do
  scope path: "/admin", as: "admin" do
    get "/", to: "admin/sessions#new", as: :login
    get "/auth/:provider/callback", to: "admin/sessions#create"
    delete "/", to: "admin/sessions#destroy", as: :logout

    authenticate :admin_user do
      yield if block_given?
    end
  end
end
```

### 3. View Extension Points
```ruby
content_for :admin_head_extra      # Additional CSS/JS
content_for :admin_sidebar_extra   # Extra sidebar items
content_for :admin_header_extra    # Header customizations
content_for :admin_footer_extra    # Footer additions
content_for :admin_breadcrumbs     # Breadcrumb customization
```

### 4. Component Extension System
```ruby
Panda::Core::Admin::ComponentRegistry.register(:statistics, StatisticsComponent)
Panda::Core::Admin::ComponentRegistry.register(:user_activity, UserActivityComponent)
```

### 5. Event Hooks
```ruby
Panda::Core.on(:user_created) { |user| track_user_creation(user) }
Panda::Core.on(:user_login) { |user| record_visit(user) }
Panda::Core.on(:admin_action) { |user, action, resource| audit_log(user, action, resource) }
```

## Migration Strategy

### Phase 1: Establish Authentication Foundation
1. Move User model and authentication logic to panda-core
2. Move OAuth provider system and configuration
3. Move session management and CurrentAttributes
4. Update panda-cms to depend on core authentication

### Phase 2: Admin UI Framework
1. Move base admin components to panda-core
2. Establish hook system for navigation and dashboard
3. Move admin layout with extension points
4. Update panda-cms to use core admin framework

### Phase 3: Extension Points
1. Implement configuration hooks
2. Add view content areas
3. Create component registry system
4. Add event system for extensibility

## Benefits of This Architecture

### For panda-core:
- Becomes useful foundation for ecosystem
- Provides authentication out of the box
- Establishes consistent admin UI patterns
- Remains lightweight with extension points

### For panda-cms:
- Removes authentication boilerplate
- Focuses on content management features
- Inherits security updates from core
- Can extend admin UI consistently

### For Future panda-* Gems:
- Authentication system ready to use
- Admin UI framework available
- Consistent patterns across ecosystem
- OAuth integration included

### For Users:
- Consistent experience across Panda tools
- Single authentication system
- Reduced complexity in setup
- Better security through centralization

## Implementation Considerations

### Backwards Compatibility
- Use deprecation warnings for old panda-cms authentication classes
- Provide migration guides for existing applications
- Maintain current API surface during transition

### Testing Strategy
- Move relevant authentication tests to panda-core
- Ensure panda-cms tests still pass with core authentication
- Add integration tests between core and cms

### Documentation Updates
- Update README files to reflect new architecture
- Create migration guides for existing users
- Document new hook system and extension points

This architecture transforms panda-core from a minimal utility library into a proper foundation for the Panda ecosystem, while keeping panda-cms focused on content management rather than authentication concerns.
