# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with panda-core.

## Development Workflow

**IMPORTANT: All test commands and Rails commands must be run from the `spec/dummy` directory.**

The dummy Rails application in `spec/dummy` provides the test environment for the engine. When running tests or Rails tasks:
- Change to `spec/dummy` directory first
- Run commands like `bundle exec rspec`, `rails db:migrate`, etc. from there
- The dummy app's database configuration supports both PostgreSQL (default) and SQLite (via `DATABASE_ADAPTER=sqlite` env var)

### Database Support

Panda Core supports both PostgreSQL and SQLite3 for development and testing:

**PostgreSQL (default):**
```bash
bundle exec rails db:create db:migrate
bundle exec rspec
```

**SQLite3:**
```bash
DATABASE_ADAPTER=sqlite bundle exec rails db:migrate
DATABASE_ADAPTER=sqlite bundle exec rspec
```

**Cross-Database UUID Support:**
- UUIDs work identically on both databases via the `HasUUID` concern
- PostgreSQL uses native `gen_random_uuid()` function
- SQLite uses `SecureRandom.uuid` at the application level
- All models with UUID primary keys automatically include `HasUUID`

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

## CSS Compilation

### Overview

Panda Core uses a unified CSS compilation system that compiles Tailwind CSS for **all registered Panda modules** into a single consolidated CSS file. The ModuleRegistry system allows each Panda gem to register its view templates and components, which are then automatically included in the CSS compilation.

### The ModuleRegistry System

Each Panda gem registers itself during engine initialization:

```ruby
# In panda-core/lib/panda/core/engine.rb
Panda::Core::ModuleRegistry.register(
  gem_name: "panda-core",
  engine: "Panda::Core::Engine",
  paths: {
    builders: "app/builders/panda/core/**/*.rb",
    components: "app/components/panda/core/**/*.rb",
    helpers: "app/helpers/panda/core/**/*.rb",
    views: "app/views/panda/core/**/*.erb",
    javascripts: "app/assets/javascript/panda/core/**/*.js"
  }
)
```

When CSS compilation runs, it automatically discovers and includes **all loaded modules** (panda-core, panda-cms, cms-pro, etc.).

### Compiling CSS

**Rake task (recommended):**
```bash
# From any panda gem directory
bundle exec rake app:panda:compile_css

# From spec/dummy directory
bundle exec rake panda:compile_css
```

**Wrapper script:**
```bash
# Simple convenience wrapper
bin/compile-css
```

### What Happens

1. Task queries ModuleRegistry for all loaded Panda modules
2. Builds Tailwind CLI command scanning all registered file paths
3. Compiles using Tailwind CSS v4 with minification
4. **Always outputs to panda-core** (auto-locates the gem):
   - `core/public/panda-core-assets/panda-core.css` (~72 KB)
   - `core/public/panda-core-assets/panda-core-{version}.css`

**Key insight:** Running the task from panda-cms will still output CSS to panda-core's directory. The task finds panda-core using `Gem::Specification.find_by_name` and puts the CSS there automatically.

### Included Content

The compiled CSS includes Tailwind classes from:

- **panda-core**: Admin UI, forms, buttons, layouts, components
- **panda-cms**: CMS views and components (when loaded)
- **cms-pro**: Pro features (when loaded)
- **Any registered modules**: Via ModuleRegistry

This single-file approach reduces HTTP requests and ensures consistent styling across the entire Panda ecosystem.

### When to Compile

- After changing Tailwind classes in any Panda gem
- Before creating a release
- When tests need updated CSS
- After adding new components or views

### Tailwind Configuration

**Source:** `app/assets/tailwind/application.css`
**Version:** Tailwind CSS v4 (CSS-based config with `@theme`)
**Themes:** `default` (purple), `sky` (blue)

## JavaScript Architecture

### Overview

All Panda gems use an **importmap-based architecture** with individual ES modules. JavaScript files are served as individual modules via custom Rack middleware - **no compilation or bundling required**.

**Key principle:** JavaScript is NOT compiled. Individual `.js` files are served directly from `app/javascript/panda/[gem]/` in each gem.

### How It Works

1. **ModuleRegistry** - Each gem registers its JavaScript paths during engine initialization
2. **JavaScriptMiddleware** - Intercepts `/panda/*` requests and serves files from registered gems
3. **Importmap** - Browser loads modules using native ES imports
4. **No Build Step** - Files served directly, no webpack/esbuild/rollup needed

### Example Flow

```
Browser Request → GET /panda/core/controllers/toggle_controller.js
                ↓
JavaScriptMiddleware → Finds file in panda-core's app/javascript/
                ↓
Serves raw ES module → Content-Type: application/javascript
```

### Importmap Configuration

Each gem defines its JavaScript imports in `config/importmap.rb`:

```ruby
# panda-core/config/importmap.rb
pin "panda/core/application", to: "/panda/core/application.js"
pin_all_from Panda::Core::Engine.root.join("app/javascript/panda/core/controllers"),
             under: "controllers", to: "/panda/core/controllers"
```

### File Structure

```
app/javascript/panda/core/
├── application.js          # Main entry point
├── controllers/            # Stimulus controllers
│   ├── toggle_controller.js
│   ├── menu_controller.js
│   └── ...
└── vendor/                 # Vendored dependencies
    └── @hotwired--stimulus.js
```

### Benefits of This Approach

- **No compilation** - Faster development iteration
- **Better caching** - Individual files = granular browser caching
- **Simpler debugging** - Source maps not needed, files are unmodified
- **Consistent across gems** - All Panda modules use same pattern
- **Native ES modules** - Leverages browser-native module loading

### Legacy Note

You may find old compiled bundle files (like `panda-core-0.1.16.js`) in test directories. These are **legacy artifacts** from before the importmap migration and should be ignored/deleted. The current architecture does not create or use compiled bundles.

## Code Quality Commands

```bash
# Run YAML linter
yamllint -c .yamllint .
```
- In this directory, always run tests from spec/dummy