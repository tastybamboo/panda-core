# Avatar Handling in Panda Core

## Overview

Panda Core provides comprehensive avatar management with automatic downloading, optimization, and variants for users who authenticate via OAuth providers (Google, GitHub, Microsoft). This prevents rate-limiting issues (429 errors) and ensures optimal performance across different display contexts.

## Key Features

- ✅ **Automatic Download**: Fetches avatars from OAuth providers on first login
- ✅ **Image Optimization**: Converts images to WebP format with configurable quality
- ✅ **Multiple Variants**: Generates thumb, small, medium, and large sizes
- ✅ **Configurable Processor**: Support for vips or mini_magick
- ✅ **Lazy Loading**: Components include lazy loading attributes
- ✅ **Graceful Fallback**: Works without image processor, falls back to initials

## How It Works

### 1. First Login

When a user logs in for the first time:

- The OAuth provider returns a profile image URL (e.g., Google avatar URL)
- `AttachAvatarService` downloads the image from the OAuth provider
- The image is optimized using the configured processor (vips or mini_magick):
  - Resized to max dimension (800px default)
  - Converted to WebP format
  - Metadata stripped for privacy/file size
  - Quality set to 85% default
- The optimized image is stored as an Active Storage attachment
- Avatar variants are automatically generated (thumb, small, medium, large)
- The OAuth avatar URL is tracked in `oauth_avatar_url` column

### 2. Subsequent Logins

On each subsequent login:

- The system checks if the OAuth avatar URL has changed
- If changed, or if no avatar is attached, the new avatar is downloaded
- Otherwise, the existing stored avatar is used

### 3. Avatar Display

The `UserDisplayComponent` uses the `user.avatar_url(size:)` method which:

- Returns the appropriate variant URL if an avatar is attached and size is specified
- Returns the original Active Storage blob path if attached and no size specified
- Falls back to the OAuth provider URL if no avatar is attached yet
- Returns `nil` if neither is available (shows initials instead)
- Includes `loading="lazy"` attribute for improved page load performance

**Available Sizes:**
- `:thumb` - 50×50px
- `:small` - 100×100px (used in UserDisplayComponent)
- `:medium` - 200×200px
- `:large` - 400×400px
- `nil` - Original optimized image (up to 800×800px)

## Database Schema

### New Column: `oauth_avatar_url`

```ruby
add_column :panda_core_users, :oauth_avatar_url, :string
```

This column tracks the OAuth provider's avatar URL to detect when it changes.

### Active Storage Tables

Standard Active Storage tables are used:

- `active_storage_blobs` - Stores avatar file metadata
- `active_storage_attachments` - Links avatars to user records
- `active_storage_variant_records` - Stores image variants (if used)

## Service: AttachAvatarService

Located at: `app/services/panda/core/attach_avatar_service.rb`

### Features

- Downloads avatars from OAuth provider URLs
- Validates file size (max 5MB before optimization)
- Optimizes images using configurable processor:
  - **vips** (default, faster) - Requires libvips installation
  - **mini_magick** (fallback) - Requires ImageMagick installation
  - Graceful fallback to original image if processor unavailable
- Converts all formats to WebP for optimal file size
- Resizes to maximum dimension (800px default)
- Strips metadata for privacy and smaller file size
- Handles timeouts and errors gracefully
- Updates tracking URL after successful download

### Usage

```ruby
Panda::Core::AttachAvatarService.call(
  user: current_user,
  avatar_url: "https://example.com/avatar.jpg"
)
```

### Image Processor Requirements

**For vips (recommended):**

```bash
# macOS
brew install vips

# Ubuntu/Debian
apt-get install libvips-dev

# Add to Gemfile
gem 'image_processing', '~> 1.2'
```

**For mini_magick (alternative):**

```bash
# macOS
brew install imagemagick

# Ubuntu/Debian
apt-get install imagemagick

# Add to Gemfile
gem 'image_processing', '~> 1.2'
```

**Without image processor:**

The service will still work but skip optimization, storing the original image from the OAuth provider.

## User Model Methods

### `#avatar_url(size: nil)`

Returns the URL for displaying the user's avatar with optional size parameter:

```ruby
# Original optimized image (up to 800×800px)
user.avatar_url
# => "/rails/active_storage/blobs/.../avatar.webp"

# Small variant (100×100px) - used in components
user.avatar_url(size: :small)
# => "/rails/active_storage/representations/.../avatar.webp"

# Thumbnail variant (50×50px)
user.avatar_url(size: :thumb)
# => "/rails/active_storage/representations/.../avatar.webp"

# Medium variant (200×200px)
user.avatar_url(size: :medium)
# => "/rails/active_storage/representations/.../avatar.webp"

# Large variant (400×400px)
user.avatar_url(size: :large)
# => "/rails/active_storage/representations/.../avatar.webp"
```

**Priority:**

1. Active Storage variant path (if attached and size specified)
2. Active Storage attachment path (if attached, no size)
3. OAuth provider URL (if no attachment)
4. `nil` (if neither available)

**Variants:**

Variants are preprocessed on upload for optimal performance. All variants maintain aspect ratio using `resize_to_limit`.

## Testing

Tests are included for:

- Active Storage avatar attachment and variants
- Avatar downloading service with optimization
- Image optimization with vips
- User model avatar handling with size parameter
- Avatar URL method behavior with variants
- OAuth authentication flow with avatars
- Component integration with lazy loading
- Graceful fallback when optimization fails

See:

- `spec/models/panda/core/user_spec.rb`
- `spec/services/panda/core/attach_avatar_service_spec.rb`
- `spec/components/panda/core/admin/user_display_component_spec.rb`

**Key Test Coverage:**

- All 4 variant sizes (thumb, small, medium, large)
- Image optimization with WebP conversion
- Metadata stripping and quality settings
- HTML escaping in component rendering
- Fallback to original image on optimization failure

## Error Handling

The avatar service handles errors gracefully:

- Network failures during download
- File size limit exceeded (> 5MB)
- Invalid content types
- Timeout errors
- Image processor not available (LoadError)
- Image optimization failures

When optimization fails, the service falls back to storing the original image. Errors are logged but don't prevent user authentication. Users will fall back to initials-based avatars if avatar attachment fails completely.

## Configuration

### Avatar Settings

Configure avatar behavior in your initializer:

```ruby
# config/initializers/panda_core.rb
Panda::Core.configure do |config|
  # Image processor: :vips (faster, recommended) or :mini_magick
  config.avatar_image_processor = :vips

  # Max file size before optimization (default: 5MB)
  config.avatar_max_file_size = 5.megabytes

  # Max dimension for optimization (default: 800px)
  config.avatar_max_dimension = 800

  # Optimization quality 0-100 (default: 85)
  config.avatar_optimization_quality = 85

  # Customize variant sizes (default shown)
  config.avatar_variants = {
    thumb: {resize_to_limit: [50, 50]},
    small: {resize_to_limit: [100, 100]},
    medium: {resize_to_limit: [200, 200]},
    large: {resize_to_limit: [400, 400]}
  }
end
```

### Active Storage

Avatar storage uses Active Storage, configured in `config/storage.yml`:

```yaml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

development:
  service: Disk
  root: <%= Rails.root.join("storage") %>

production:
  service: S3
  # ... S3 configuration
```

## Security Considerations

- File size is limited to 5MB to prevent abuse
- Downloads have 10-second timeouts
- Only image content types are accepted
- URLs are validated before download
- Metadata is stripped from images (privacy + security)
- Images are re-encoded during optimization (sanitization)
- Only trusted OAuth provider URLs are processed
- Component output is properly HTML-escaped

## Performance Considerations

### Optimization Benefits

- **WebP format**: 25-35% smaller than JPEG with similar quality
- **Variants**: Only generate/serve the size needed for each context
- **Preprocessing**: Variants generated once on upload, not on-demand
- **Lazy loading**: Images load only when visible in viewport
- **CDN-ready**: Optimized images work well with CDN caching

### File Size Comparison

Example 500KB JPEG from OAuth provider:
- Original JPEG: 500KB
- Optimized WebP (800×800): ~150KB (70% reduction)
- Small variant (100×100): ~5KB
- Thumb variant (50×50): ~2KB

## User-Uploaded Avatars

Users can upload custom avatars via the My Profile page:

**Features:**
- File upload with drag-and-drop support (via FormBuilder)
- Accepts PNG, JPEG, GIF, and WebP formats
- Shows preview of current avatar
- Displays filename and file size
- Automatically optimized using the same pipeline as OAuth avatars
- Generates all variants (thumb, small, medium, large)

**Implementation:**
- Controller permits `:avatar` parameter (`app/controllers/panda/core/admin/my_profile_controller.rb:46`)
- File input field in edit view (`app/views/panda/core/admin/my_profile/edit.html.erb:26-28`)
- Uses Active Storage's built-in attachment handling
- No additional configuration needed

## Future Enhancements

See GitHub issue [#28](https://github.com/tastybamboo/panda-core/issues/28) for planned improvements:

- [x] Image optimization with WebP conversion
- [x] Avatar variants for different display sizes
- [x] User-uploaded avatars (implemented in My Profile page)
- [ ] Background job processing for optimization (currently synchronous)
- [ ] CDN integration examples
- [ ] Bulk avatar management in admin UI
