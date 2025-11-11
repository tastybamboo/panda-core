# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.4] - 2025-11-11

### Added

- Avatar variants with multiple sizes (thumb 50×50, small 100×100, medium 200×200, large 400×400)
- Image optimization with configurable processor (vips or mini_magick)
- Automatic WebP conversion for all avatars with 85% quality default
- Lazy loading support for avatar images in components
- Configuration options for avatar optimization:
  - `avatar_image_processor` - Choose between :vips or :mini_magick
  - `avatar_max_file_size` - Maximum file size before optimization (default 5MB)
  - `avatar_max_dimension` - Maximum dimension for optimization (default 800px)
  - `avatar_optimization_quality` - Quality setting 0-100 (default 85)
  - `avatar_variants` - Customize variant sizes
- Comprehensive documentation in AVATAR_HANDLING.md covering:
  - Image processor installation requirements
  - Configuration examples
  - Performance considerations with file size comparisons
  - User-uploaded avatars via My Profile page
  - Security considerations

### Changed

- `User#avatar_url` now accepts optional `size:` parameter for variants
- AttachAvatarService optimizes images during OAuth avatar download
- UserDisplayComponent uses small variant (100×100) with lazy loading
- Improved avatar handling with graceful fallback when processor unavailable
- Enhanced test coverage for avatar variants and optimization

### Fixed

- Component specs updated for new `avatar_url(size:)` signature
- Mock users in tests now properly implement avatar_url method

### Performance

- Avatar file sizes reduced by ~70% through WebP optimization
- Variants prevent serving oversized images in components
- Preprocessed variants for faster page loads

## [0.6.0] - 2025-11-04

### Added
- Active Storage configuration for avatar uploads in test environment
- AttachAvatarService for handling OAuth provider avatar downloads
- BreadcrumbComponent for navigation breadcrumbs
- PageHeaderComponent for consistent page headers with breadcrumbs and action buttons
- Avatar URL field (`oauth_avatar_url`) to User model
- TailwindPlus Elements JavaScript integration
- Alert controller for flash message auto-dismiss
- FileGalleryComponent for file management UI
- Comprehensive test coverage for new components and services
- Test fixtures for avatar handling

### Fixed
- Test suite configuration for Active Storage
- File path references in specs to use Engine.root instead of Rails.root
- Avatar attachment persistence in tests with proper save and reload
- Component specs to match actual implementation behavior
- Deprecated `:unprocessable_entity` status replaced with `:unprocessable_content`
- Panel heading padding consistency (px-4 py-3 instead of p-4)
- Table component empty state rendering
- UserDisplayComponent to properly use `avatar_url` attribute
- Standard Ruby linting violations (16 auto-fixes)
- Unless-else blocks converted to positive case first
- Nil lambda properties across components

### Changed
- Improved test reliability with proper Active Storage setup
- Enhanced component rendering tests
- Updated documentation for authentication testing
- Improved BaseService with better result handling

### Deprecated
- None

### Removed
- None

### Security
- None

## [0.4.1] - 2025-10-30

### Added
- Debug utility module for development debugging
  - Environment-based activation via `PANDA_DEBUG` environment variable
  - Debug logging with timestamps and custom prefixes
  - Object inspection with awesome_print support (falls back to pp)
  - HTTP request debugging for Net::HTTP calls via `enable_http_debug!`
  - No impact when PANDA_DEBUG is not enabled

## [0.4.0] - 2025-10-30

### Added
- Complete Phlex component architecture for admin UI
  - Base component class with Literal properties support
  - Tailwind CSS class merging with TailwindMerge
  - Development-mode debugging comments
- New admin UI components (Phlex-based):
  - ButtonComponent with action-based styling
  - ContainerComponent with slot support
  - FlashMessageComponent with auto-dismiss
  - HeadingComponent with level variants
  - PanelComponent for content sections
  - SlideoverComponent for modals
  - StatisticsComponent with gradient styling
  - TabBarComponent with mobile support
  - TableComponent with empty states
  - TagComponent for status indicators
  - UserActivityComponent
  - UserDisplayComponent with avatar support
  - FormErrorComponent, FormInputComponent, FormSelectComponent
- AdminController base class for consistent admin interface
- Configurable default_theme option
- `current_theme` column to panda_core_users table
- Rails controller testing support

### Fixed
- Test suite now fully passing (103/103 tests)
- PostgreSQL prepared statement caching issues in tests
- Component spec CSS class expectations
- Breadcrumb tests to use Breadcrumb objects
- Dynamic field tests with proper column reset
- Set current request details before authentication
- Handle callable dashboard_redirect_path in controllers
- Use is_admin column consistently in User model
- Include SessionsHelper in BaseController
- Load Font Awesome 7.1.0 from CDN

### Changed
- Migrated from ERB templates to Phlex components
- All admin controllers now inherit from BaseController
- Unified configuration with consistent task naming
- Disabled asset caching in development mode
- Consolidated all Panda admin interface styling into Core

### Development
- Added rails-controller-testing gem for controller specs
- Disabled PostgreSQL prepared statements in test environment
- Improved test infrastructure and fixtures

## [0.3.0] - 2025-XX-XX

Initial release of panda-core as a standalone gem.

[0.4.0]: https://github.com/tastybamboo/panda-core/releases/tag/v0.4.0
[0.3.0]: https://github.com/tastybamboo/panda-core/releases/tag/v0.3.0
