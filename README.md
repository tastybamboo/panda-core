# Panda Core

Core functionality shared between Panda Software gems:

- [Panda CMS](https://github.com/tastybamboo/panda-cms)
- [Panda Editor](https://github.com/tastybamboo/panda-editor)

## Requirements

### Database Support

Panda Core supports both PostgreSQL and SQLite3 databases:

**PostgreSQL** (recommended for production):

- PostgreSQL 12, 15, 17, 18
- Tested against all versions in CI
- Uses native UUID generation (`gen_random_uuid()`)

**SQLite3** (development/testing):

- SQLite 3.x
- Uses application-level UUID generation
- Ideal for local development and testing

Both databases are tested extensively in CI across multiple Ruby and Rails versions to ensure cross-database compatibility.

## Installation

Add this line to your application's Gemfile:

```
gem 'panda-core'
```

And then execute:

```
bundle install
```

## Setup

### 1. Run the Install Generator

This will:

- Add required gem dependencies
- Create an initializer
- Mount the engine in your routes

```
rails generate panda:core:install
```

### 2. Install Configuration Templates

Panda Core provides standard configuration files that can be used across all Panda gems to ensure consistency.

```
rails generate panda:core:templates
```

This will copy the following configuration files to your project:

- `.github/workflows/ci.yml` - GitHub Actions CI workflow
- `.github/dependabot.yml` - Dependabot configuration
- `.erb_lint.yml` - ERB linting rules
- `.eslintrc.js` - ESLint configuration
- `.gitattributes` - Git file handling rules
- `.gitignore` - Standard git ignore rules
- `.lefthook.yml` - Git hooks configuration
- `.rspec` - RSpec configuration
- `.standard.yml` - Ruby Standard configuration

### 3. Configure Dependencies

The gems listed in the `panda-core.gemspec` will be added to your Gemfile (or, if this an engine, your `gem-name.gemspec` file).

Make sure to follow the setup instructions for each of these gems.

## Configuration

Panda Core is configured in `config/initializers/panda.rb`. The install generator creates this file with a complete default configuration:

```ruby
# config/initializers/panda.rb
Panda::Core.configure do |config|
  config.admin_path = "/admin"

  config.login_page_title = "Panda Admin"
  config.admin_title = "Panda Admin"

  config.authentication_providers = {
    google_oauth2: {
      enabled: true,
      name: "Google",
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: {
        scope: "email,profile",
        prompt: "select_account",
        hd: "yourdomain.com" # Restrict to specific domain
      }
    }
  }

  # Core settings
  config.session_token_cookie = :panda_session
  config.user_class = "Panda::Core::User"
  config.user_identity_class = "Panda::Core::UserIdentity"
  config.storage_provider = :active_storage
  config.cache_store = :memory_store

  # Optional editor configuration
  # config.editor_js_tools = []
  # config.editor_js_tool_config = {}
end
```

### Authentication Providers

Panda Core supports multiple OAuth providers. Configure your credentials in Rails credentials:

```yaml
# config/credentials.yml.enc
google:
  client_id: "your-google-client-id"
  client_secret: "your-google-client-secret"

microsoft:
  client_id: "your-microsoft-client-id"
  client_secret: "your-microsoft-client-secret"
```

Then reference them in your initializer. You can enable multiple providers simultaneously.

### Admin Path

The `admin_path` setting controls where the admin interface is mounted (default: `/admin`). You can customize this to avoid route conflicts or match your preferences:

```ruby
config.admin_path = "/manage"  # Custom admin path
```

This is useful when:
- You want to avoid conflicts with existing routes
- You prefer a different URL structure
- You're running multiple admin interfaces
- You need different admin paths per environment

### Theming the Admin Chrome

The admin UI's chrome (panels, tables, status badges, form inputs, the
custom-select trigger, checkbox accent, and the sidebar/login gradient) reads
from CSS custom properties, declared per theme in
`app/assets/tailwind/application.css`. Two themes ship with the gem
(`default` and `sky`); host apps can bring their own without patching the gem:

1. **Register the theme** so it appears in the My Profile dropdown and can be
   the default. Assigning `available_themes` **replaces** the built-in list,
   so include any built-ins you still want to offer:

   ```ruby
   Panda::Core.configure do |config|
     config.available_themes = [["Default", "default"], ["Acme", "acme"]]
     config.default_theme = "acme"
     config.additional_head_content = -> {
       %(<link rel="stylesheet" href="/assets/acme-admin-theme.css">)
     }
   end
   ```

2. **Supply the variable block** in the stylesheet you inject. Any token you
   leave undefined falls back to the gem default:

   ```css
   html[data-theme='acme'] {
     /* Brand colour scale (used by buttons, links, focus rings, ...) */
     --color-primary-500: #2d6a4f;
     --color-primary-600: #1b4332;

     /* Sidebar / login-page gradient */
     --gradient-admin-from: #1b4332;
     --gradient-admin-to: #2d6a4f;

     /* Admin chrome tokens (see application.css for the full catalogue) */
     --panda-panel-bg: #ffffff;
     --panda-panel-border: #f1f3f5;
     --panda-panel-radius: 12px;
     --panda-table-header-bg: transparent;
     --panda-badge-success-bg: #d3f9d8;
     --panda-badge-success-fg: #2b8a3e;
     --panda-input-border: #dee2e6;
     --panda-input-radius: 8px;
     --panda-checkbox-accent: #1b4332;
   }
   ```

Every admin layout (including the login page) stamps
`<html data-theme="...">` from the signed-in user's `current_theme`, falling
back to `config.default_theme`, and renders `additional_head_content` in its
`<head>` — so the theme applies automatically once configured.

### Asset Pipeline

Panda Core provides the **single source of truth** for all Panda admin interface styling. This includes:

- Base Tailwind CSS utilities and theme system
- EditorJS content styles (used by Panda CMS)
- Admin component styles
- Form styles and typography

**Asset Compilation**

Panda Core uses Tailwind CSS v4 to compile all admin interface styling.

**Quick Start** - Compile full CSS (Core + CMS):

Core's Rack middleware serves `/panda-core-assets/` from the gem's `public/` directory:

```ruby
# In Core's engine.rb
config.app_middleware.use(Rack::Static,
  urls: ["/panda-core-assets"],
  root: Panda::Core::Engine.root.join("public")
)
```

This means:
- ✅ CMS and other gems automatically load CSS from Core
- ✅ No copying needed - served directly from gem
- ✅ Version changes are instant (just restart server)
- ✅ Single source of truth for all admin styling

**What Gets Compiled:**

The compilation process:
- Scans all Core and registered modules' views/components for Tailwind classes
- Includes EditorJS content styles for rich text editing
- Applies theme variables for default and sky themes
- Outputs a single minified CSS file (~37KB)

**Asset Serving**

Panda Core automatically serves compiled assets from `/panda-core-assets/` using Rack::Static middleware configured in the engine.

**How Panda CMS Uses Core Styling**

Panda CMS depends on Panda Core and loads its CSS automatically:

```erb
<!-- In CMS views -->
<link rel="stylesheet" href="/panda-core-assets/panda-core.css">
```

This ensures all Tailwind classes used across the Panda ecosystem are included in the compiled CSS.

To regenerate CSS, run (from inside `panda-core` or another engine):

```
bundle exec rake app:panda:compile_css
```

You should run this from the top-most or last registered engine in your application.

**Theme System**

Panda Core provides two built-in themes accessible via `data-theme` attribute:

- `default`: Purple/pink color scheme
- `sky`: Blue color scheme

Themes use CSS custom properties that can be referenced in your styles:
- `--color-white`, `--color-black`
- `--color-light`, `--color-mid`, `--color-dark`
- `--color-highlight`, `--color-active`, `--color-inactive`
- `--color-warning`, `--color-error`

## Development

After checking out the repo:

1. Run setup:

```
bin/setup
```

2. Run the test suite:

```
bundle exec rspec
```

3. Run the linter:

```
bundle exec standardrb
```

## Testing

The gem includes several types of tests:

- Generator tests for installation and template copying
- System tests using Capybara
- Unit tests for core functionality

To run specific test types:

```
# Run all tests
bundle exec rspec
```

```
# Run only generator tests
bundle exec rspec spec/generators
```

```
# Run only system tests
bundle exec rspec spec/system
```

### CI/Docker parity

The GitHub Actions workflow now builds a reusable CI image (Chrome + PostgreSQL + Ruby). You can reuse it locally:

```
bin/ci build   # build the CI image locally
bin/ci test    # run the suite inside the container
```

To dry-run the workflow with `act` (uses the locally built image tagged `:local`):

```
act -j test-stable
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

Bug reports and pull requests are welcome on GitHub at https://github.com/tastybamboo/panda-core.

## Releasing

Panda Core uses automated releases via GitHub Actions. When changes to `lib/panda/core/version.rb` are merged to the `main` branch:

1. The CI workflow runs tests
2. If tests pass, the auto-release workflow triggers
3. A git tag is created automatically (e.g., `v0.2.1`)
4. The gem is built and published to RubyGems
5. A GitHub release is created with changelog

## License

Copyright 2024-2025 Otaina Limited. The gem is available as open source under the terms of the [BSD 3-Clause License](https://opensource.org/licenses/BSD-3-Clause).
