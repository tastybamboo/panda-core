# Panda Core Asset Compilation Guide

## Overview

Panda Core is the **single source of truth** for all Panda admin interface styling. This includes:

- Base Tailwind CSS utilities and theme system
- EditorJS content styles (used by Panda CMS)
- Admin component styles (forms, buttons, panels, etc.)
- Theme variables (default and sky themes)

All Panda gems (CMS, Editor, etc.) load CSS from Core via Rack middleware - **no copying or duplication needed**.

## Automatic Compilation in Test Environments

**New in v0.8+**: Panda Core automatically compiles CSS when tests run, using **timestamp-based filenames** for automatic cache busting:

```bash
# First test run - auto-compiles CSS
RAILS_ENV=test bundle exec rspec

# Output:
# 🐼 [Panda Core] Auto-compiling CSS for test environment...
# 🐼 [Panda Core] CSS compilation successful (72521 bytes)
```

**What gets created:**
- `public/panda-core-assets/panda-core-1762886534.css` (timestamp-based)
- `public/panda-core-assets/panda-core.css` → symlink to timestamp file

**How it works:**
1. Engine initializer checks for existing compiled CSS on Rails boot
2. If none found, runs `bundle exec rake panda:core:assets:release`
3. Creates timestamp-based file + unversioned symlink
4. Asset loader finds the latest timestamp file automatically

**Benefits:**
- ✅ Zero manual compilation needed for testing
- ✅ Automatic cache busting without version bumps
- ✅ Works in both local and CI environments
- ✅ Consistent with panda-cms JavaScript compilation

**Environment variable override:**
```bash
# Force recompilation
PANDA_CORE_AUTO_COMPILE=true bundle exec rails server
```

## Architecture

### How CSS is Served

Core's `engine.rb` configures Rack::Static middleware:

```ruby
config.app_middleware.use(
  Rack::Static,
  urls: ["/panda-core-assets"],
  root: Panda::Core::Engine.root.join("public")
)
```

This means:
- CSS is served from Core gem's `public/panda-core-assets/` directory
- Path `/panda-core-assets/panda-core.css` loads from wherever Core is installed
- No version-specific paths needed in development
- Changes to CSS in Core are immediately available after server restart

### Why Core Owns All Styling

**Before**: CMS compiled its own CSS, leading to:
- ❌ Duplication of theme definitions
- ❌ Inconsistent styling across gems
- ❌ Two compilation pipelines to maintain
- ❌ Version mismatches between Core and CMS styles

**After**: Core compiles all CSS:
- ✅ Single source of truth for admin interface
- ✅ Consistent themes across all Panda gems
- ✅ One compilation pipeline
- ✅ Automatic style updates when Core updates

## Development Workflows

### Daily Development: Core Styles Only

When working on **Core components** (login page, session views, base layouts):

```bash
cd /path/to/panda-core

bundle exec tailwindcss \
  -i app/assets/tailwind/application.css \
  -o public/panda-core-assets/panda-core.css \
  --minify
```

**Result**: ~14KB file with only Core utility classes

**When to use**:
- Editing Core views/components
- Working on authentication UI
- Updating theme variables
- Testing Core in isolation

### Daily Development: Full Admin Stack

When working on **CMS components** or need all admin styles:

```bash
cd /path/to/panda-core

bundle exec tailwindcss \
  -i app/assets/tailwind/application.css \
  -o public/panda-core-assets/panda-core.css \
  --content '../cms/app/views/**/*.erb' \
  --content '../cms/app/components/**/*.rb' \
  --content '../cms/app/javascript/**/*.js' \
  --content 'app/views/**/*.erb' \
  --content 'app/components/**/*.rb' \
  --minify
```

**Result**: ~37KB file with Core + CMS utility classes

**When to use**:
- Working on CMS admin interface
- Testing EditorJS styles
- Developing new CMS features
- Before committing CSS changes

**Important**: This requires both Core and CMS repos in sibling directories:
```
/path/to/panda/
├── core/
└── cms/
```

### Seeing Changes

After recompiling CSS:

```bash
# In your application (neurobetter, CMS dummy app, etc.)
bin/dev
# or
bundle exec rails server

# Visit http://localhost:3000/manage (or your admin path)
# Hard refresh (Cmd+Shift+R) to clear CSS cache
```

Changes are **instant** - the server loads CSS from Core's public directory.

## Release Workflow

### Before Releasing Core

1. **Compile full CSS with all content**:

```bash
cd /path/to/panda-core

bundle exec tailwindcss \
  -i app/assets/tailwind/application.css \
  -o public/panda-core-assets/panda-core.css \
  --content '../cms/app/views/**/*.erb' \
  --content '../cms/app/components/**/*.rb' \
  --content '../cms/app/javascript/**/*.js' \
  --content 'app/views/**/*.erb' \
  --content 'app/components/**/*.rb' \
  --minify
```

2. **Verify file size** (~37KB):

```bash
ls -lh public/panda-core-assets/panda-core.css
```

3. **Commit the CSS**:

```bash
git add public/panda-core-assets/panda-core.css
git commit -m "Update compiled CSS for v0.2.4"
```

### Creating Versioned Release Assets (Optional)

For tagged releases, you can create versioned CSS files:

```bash
cd /path/to/panda-core

# Update version first
# Edit lib/panda/core/version.rb

# Compile to versioned file
VERSION=$(ruby -r ./lib/panda/core/version.rb -e 'puts Panda::Core::VERSION')

bundle exec tailwindcss \
  -i app/assets/tailwind/application.css \
  -o public/panda-core-assets/panda-core-${VERSION}.css \
  --content '../cms/app/views/**/*.erb' \
  --content '../cms/app/components/**/*.rb' \
  --content '../cms/app/javascript/**/*.js' \
  --content 'app/views/**/*.erb' \
  --content 'app/components/**/*.rb' \
  --minify

# Update symlink
cd public/panda-core-assets
ln -sf panda-core-${VERSION}.css panda-core.css

# Commit both files
git add panda-core-${VERSION}.css panda-core.css
git commit -m "Add versioned CSS for v${VERSION}"
```

**Note**: In practice, only `panda-core.css` (unversioned) is required. Versioned files are useful for:
- Historical reference
- Rollback scenarios
- Debugging version-specific issues

## Tailwind Content Scanning

### How It Works

Tailwind v4 scans your code for utility classes and includes only what's used. The scanning is configured in:

**Via tailwind.config.js** (not currently working due to path resolution):
- `app/assets/tailwind/tailwind.config.js`
- Uses relative paths from config file location
- Doesn't work when CMS is in parent directory

**Via CLI flags** (current working approach):
```bash
--content '../cms/app/views/**/*.erb'
```

### What Gets Scanned

**Core content**:
- `app/views/**/*.erb` - Core view templates
- `app/components/**/*.rb` - ViewComponent classes
- `app/helpers/**/*.rb` - Helper methods with HTML generation

**CMS content** (when using `--content` flags):
- `../cms/app/views/**/*.erb` - CMS admin views
- `../cms/app/components/**/*.rb` - CMS ViewComponents
- `../cms/app/javascript/**/*.js` - Stimulus controllers with Tailwind classes
- `../cms/app/builders/**/*.rb` - Form builders

### Why File Size Changes

**14KB (Core only)**:
- Only includes classes used in Core views
- Suitable for Core development
- Missing CMS-specific utilities

**37KB (Core + CMS)**:
- Includes all utility classes used across both gems
- Required for CMS functionality
- Includes EditorJS content styles
- This is the version that should be committed

## Troubleshooting

### CSS Missing in CMS

**Symptom**: CMS admin looks unstyled

**Causes**:
1. Core CSS not compiled
2. Compiled with Core-only content (14KB file)
3. Server not restarted after recompiling

**Solution**:
```bash
# Recompile with full content
cd /path/to/panda-core
bundle exec tailwindcss -i app/assets/tailwind/application.css \
  -o public/panda-core-assets/panda-core.css \
  --content '../cms/app/views/**/*.erb' \
  --content '../cms/app/components/**/*.rb' \
  --content '../cms/app/javascript/**/*.js' \
  --content 'app/views/**/*.erb' \
  --content 'app/components/**/*.rb' \
  --minify

# Restart your server
```

### File Size Too Small

**Symptom**: `panda-core.css` is ~14KB instead of ~37KB

**Cause**: Compiled without CMS content scanning

**Solution**: Use the full command with all `--content` flags (see above)

### Changes Not Appearing

**Symptom**: CSS changes not visible after recompiling

**Causes**:
1. Browser cache
2. Server not restarted
3. Wrong Core version loaded

**Solutions**:
```bash
# Hard refresh browser
# Chrome/Firefox: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

# Restart server
# Kill existing server and restart

# Verify Core version
cd /path/to/your-app
bundle show panda-core
# Should point to local development gem

# Check loaded CSS
curl http://localhost:3000/panda-core-assets/panda-core.css | head -5
# Should show recent compilation timestamp in comment
```

### CMS Repo Not Found

**Symptom**: `--content '../cms/...'` paths don't match any files

**Cause**: Repos not in sibling directories

**Required structure**:
```
/path/to/panda/
├── core/          ← You are here
└── cms/           ← Must be here for --content '../cms/...' to work
```

**Solution**: Clone repos in correct structure or adjust paths

### CI Failures After CSS Changes

**Symptom**: CMS tests fail with styling issues

**Cause**: Forgot to commit compiled CSS

**Solution**:
```bash
# In Core repo
git status public/panda-core-assets/

# If showing untracked/modified:
git add public/panda-core-assets/panda-core.css
git commit -m "Update compiled CSS"
git push

# In CMS repo, update Core dependency:
bundle update panda-core
```

## Common Tasks

### Adding New Tailwind Classes

1. Add classes to your template:
```erb
<div class="bg-purple-500 text-white">...</div>
```

2. Recompile CSS with full content
3. Restart server
4. Verify classes work
5. Commit CSS if satisfied

### Updating Theme Colors

1. Edit `app/assets/tailwind/application.css`:
```css
html[data-theme="default"] {
  --color-highlight: 208 64 20; /* Your new color */
}
```

2. Recompile CSS (Core-only is fine for theme changes)
3. Restart server
4. Test theme switching
5. Commit both source and compiled CSS

### Creating New Theme

1. Add theme section in `application.css`:
```css
html[data-theme="forest"] {
  --color-white: 249 249 249;
  --color-black: 26 22 29;
  --color-light: 220 240 220; /* Forest green tints */
  --color-mid: 34 139 34;
  --color-dark: 0 100 0;
  /* ... etc */
}
```

2. Recompile and test
3. Update theme selector UI to include new option
4. Commit changes

## Best Practices

### DO:
✅ Compile with full content before committing
✅ Restart server after recompiling
✅ Use hard refresh to clear CSS cache
✅ Commit compiled CSS to Core repo
✅ Keep Core and CMS repos in sibling directories
✅ Verify file size (~37KB for full compilation)

### DON'T:
❌ Copy CSS files between repos
❌ Commit 14KB CSS (Core-only)
❌ Edit compiled CSS directly (edit source instead)
❌ Forget to restart server after changes
❌ Use version-specific CSS paths in development
❌ Duplicate styles between Core and CMS

## Quick Reference

```bash
# Daily development (full stack)
cd /path/to/panda-core && bundle exec tailwindcss -i app/assets/tailwind/application.css -o public/panda-core-assets/panda-core.css --content '../cms/app/views/**/*.erb' --content '../cms/app/components/**/*.rb' --content '../cms/app/javascript/**/*.js' --content 'app/views/**/*.erb' --content 'app/components/**/*.rb' --minify

# Before committing
ls -lh public/panda-core-assets/panda-core.css  # Should be ~37KB
git add public/panda-core-assets/panda-core.css
git commit -m "Update compiled CSS"

# Verify CSS loads
curl http://localhost:3000/panda-core-assets/panda-core.css | head -5
```

## Related Documentation

- [Core README](../README.md) - General Core documentation
- [CMS Asset System](../../cms/docs/assets.md) - How CMS loads Core styles
- [Tailwind v4 Docs](https://tailwindcss.com/docs) - Tailwind CSS reference
