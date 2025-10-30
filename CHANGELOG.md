# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
