# Panda Core

Core functionality shared between Panda Software gems:

- [Panda CMS](https://github.com/tastybamboo/panda-cms)
- [Panda Editor](https://github.com/tastybamboo/panda-editor)

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

### Admin Path

By default, the admin panel is available at `/admin`. You can customize this in your Panda Core initializer:

```ruby
# config/initializers/panda_core.rb
Panda::Core.configure do |config|
  # Option 1: Set directly
  config.admin_path = "/manage"

  # Option 2: Read from environment variable (recommended)
  config.admin_path = ENV.fetch("PANDA_ADMIN_PATH", "/admin")
end
```

If using environment variables, add to your `.env` file:

```bash
# .env
PANDA_ADMIN_PATH=/manage
```

**Important**: You'll need a gem like `dotenv-rails` to load environment variables from `.env` files:

```ruby
# Gemfile
gem "dotenv-rails"

# config/boot.rb (add before requiring bootsnap)
require "dotenv/load"
```

This is useful when:
- You want to avoid conflicts with existing routes
- You prefer a different URL structure for your admin panel
- You're running multiple admin interfaces
- You need different admin paths per environment (staging, production, etc.)

Remember to restart your server after changing the admin path.

### Asset Pipeline

Panda Core provides the **single source of truth** for all Panda admin interface styling. This includes:

- Base Tailwind CSS utilities and theme system
- EditorJS content styles (used by Panda CMS)
- Admin component styles
- Form styles and typography

**Asset Compilation**

Panda Core uses Tailwind CSS v4 to compile all admin interface styling.

**Quick Start** - Compile full CSS (Core + CMS):

```bash
cd /path/to/panda-core

bundle exec tailwindcss -i app/assets/tailwind/application.css \
  -o public/panda-core-assets/panda-core.css \
  --content '../cms/app/views/**/*.erb' \
  --content '../cms/app/components/**/*.rb' \
  --content '../cms/app/javascript/**/*.js' \
  --content 'app/views/**/*.erb' \
  --content 'app/components/**/*.rb' \
  --minify
```

**Result**: `panda-core.css` (~37KB) with all utility classes

**Important**: Always compile with full content before committing!

For complete documentation on:
- Development workflows (Core-only vs full stack)
- Release processes
- Troubleshooting
- Best practices

See **[docs/ASSET_COMPILATION.md](docs/ASSET_COMPILATION.md)**

**How Asset Serving Works:**

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
- Scans all Core and CMS views/components for Tailwind classes (via `tailwind.config.js`)
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

CMS no longer compiles its own CSS - all styling comes from Core.

**Content Scanning**

The `tailwind.config.js` file configures content scanning to include:
- Core views: `../../app/views/**/*.html.erb`
- Core components: `../../app/components/**/*.rb`
- CMS views: `../../../cms/app/views/**/*.html.erb`
- CMS components: `../../../cms/app/components/**/*.rb`
- CMS JavaScript: `../../../cms/app/javascript/**/*.js`

This ensures all Tailwind classes used across the Panda ecosystem are included in the compiled CSS.

**Customizing Styles**

To customize the admin interface styles:

1. Edit `app/assets/tailwind/application.css` in panda-core
2. Add custom CSS in the appropriate `@layer` (base, components, or utilities)
3. Recompile: `bundle exec tailwindcss -i app/assets/tailwind/application.css -o public/panda-core-assets/panda-core.css --minify`
4. Copy the updated CSS to test locations if needed
5. Restart your Rails server to see changes

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
