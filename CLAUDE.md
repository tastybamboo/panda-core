# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with panda-core.

## Project Overview

Panda Core is a lightweight Rails engine that provides shared development tools, configurations, and utilities for Panda CMS and other future panda-* gems. It serves as the foundation dependency that other Panda ecosystem gems build upon.

## Architecture Analysis

### Current State (Minimal Foundation)

**Core Structure:**
- **Rails Engine**: Basic engine in `lib/panda/core/engine.rb`
- **Configuration**: Uses `dry-configurable` for flexible settings in `lib/panda/core.rb`
- **Services**: Base service pattern in `lib/panda/core/services/base_service.rb`
- **Utilities**: 
  - SEO helpers (`lib/panda/core/seo.rb`)
  - Media handling (`lib/panda/core/media.rb`)
  - Sluggable concern (`lib/panda/core/sluggable.rb`)
  - OAuth providers (`lib/panda/core/oauth_providers.rb`)

**Current Configuration Options:**
```ruby
Panda::Core.configure do |config|
  config.user_class = nil
  config.authentication_providers = []
  config.storage_provider = :active_storage
  config.cache_store = :memory_store
end
```

### Recommended Migration from panda-cms

Based on analysis of panda-cms architecture, the following components should be moved to panda-core to establish it as the authentication and admin UI foundation:

#### 1. **Authentication System (High Priority)**

**Components to Move:**
- `Panda::CMS::User` → `Panda::Core::User`
- `Panda::CMS::Current` → `Panda::Core::Current` (CurrentAttributes)
- `Panda::CMS::Admin::SessionsController` → `Panda::Core::Admin::SessionsController`
- `Panda::CMS::AdminConstraint` → `Panda::Core::AdminConstraint`

**Why:** panda-cms currently implements a robust OAuth-only authentication system with support for Microsoft, Google, and GitHub providers. This should be the foundation for all Panda ecosystem gems.

**Benefits:**
- ✅ Other panda-* gems get authentication out of the box
- ✅ Consistent user management across ecosystem
- ✅ Reduced duplication of OAuth integration code
- ✅ Centralized security updates

#### 2. **Admin UI Framework (Medium Priority)**

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

#### 3. **Configuration & OAuth System (High Priority)**

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

### 1. **Configuration Hooks**
```ruby
Panda::Core.configure do |config|
  # Navigation extension point
  config.admin_navigation_items = ->(user) { [] }
  
  # Dashboard widgets extension point  
  config.admin_dashboard_widgets = ->(user) { [] }
  
  # User model extension point
  config.user_attributes = []
  config.user_associations = []
  
  # Authorization policy extension point
  config.authorization_policy = ->(user, action, resource) { user.admin? }
end
```

### 2. **Route Extension Points**
```ruby
# In panda-core routes
Panda::Core::Engine.routes.draw do
  scope path: "/admin", as: "admin" do
    # Core authentication routes
    get "/", to: "admin/sessions#new", as: :login
    get "/auth/:provider/callback", to: "admin/sessions#create"
    delete "/", to: "admin/sessions#destroy", as: :logout
    
    # Extension point for other engines
    authenticate :admin_user do
      yield if block_given?
    end
  end
end
```

### 3. **View Extension Points**
```ruby
# Admin layout provides extension areas
content_for :admin_head_extra      # Additional CSS/JS
content_for :admin_sidebar_extra   # Extra sidebar items  
content_for :admin_header_extra    # Header customizations
content_for :admin_footer_extra    # Footer additions
content_for :admin_breadcrumbs     # Breadcrumb customization
```

### 4. **Component Extension System**
```ruby
# panda-cms can register additional admin components
Panda::Core::Admin::ComponentRegistry.register(:statistics, StatisticsComponent)
Panda::Core::Admin::ComponentRegistry.register(:user_activity, UserActivityComponent)
```

### 5. **Event Hooks**
```ruby
# panda-cms can listen to core events
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
- ✅ Becomes useful foundation for ecosystem
- ✅ Provides authentication out of the box
- ✅ Establishes consistent admin UI patterns
- ✅ Remains lightweight with extension points

### For panda-cms:
- ✅ Removes authentication boilerplate
- ✅ Focuses on content management features
- ✅ Inherits security updates from core
- ✅ Can extend admin UI consistently

### For Future panda-* Gems:
- ✅ Authentication system ready to use
- ✅ Admin UI framework available
- ✅ Consistent patterns across ecosystem
- ✅ OAuth integration included

### For Users:
- ✅ Consistent experience across Panda tools
- ✅ Single authentication system
- ✅ Reduced complexity in setup
- ✅ Better security through centralization

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