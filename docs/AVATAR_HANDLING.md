# Avatar Handling in Panda Core

## Overview

Panda Core now provides automatic avatar downloading and storage for users who authenticate via OAuth providers (Google, GitHub, Microsoft). This prevents rate-limiting issues (429 errors) that occur when repeatedly accessing OAuth provider URLs directly.

## How It Works

### 1. First Login

When a user logs in for the first time:

- The OAuth provider returns a profile image URL (e.g., Google avatar URL)
- `AttachAvatarService` downloads the image from the OAuth provider
- The image is stored as an Active Storage attachment on the user record
- The OAuth avatar URL is tracked in `oauth_avatar_url` column

### 2. Subsequent Logins

On each subsequent login:

- The system checks if the OAuth avatar URL has changed
- If changed, or if no avatar is attached, the new avatar is downloaded
- Otherwise, the existing stored avatar is used

### 3. Avatar Display

The `UserDisplayComponent` uses the `user.avatar_url` method which:

- Returns the Active Storage blob path if an avatar is attached (preferred)
- Falls back to the OAuth provider URL if no avatar is attached yet
- Returns `nil` if neither is available (shows initials instead)

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
- Validates file size (max 5MB)
- Supports multiple image formats (JPEG, PNG, GIF, WebP)
- Handles timeouts and errors gracefully
- Updates tracking URL after successful download

### Usage

```ruby
Panda::Core::AttachAvatarService.call(
  user: current_user,
  avatar_url: "https://example.com/avatar.jpg"
)
```

## User Model Methods

### `#avatar_url`

Returns the URL for displaying the user's avatar:

```ruby
user.avatar_url
# => "/rails/active_storage/blobs/.../avatar.jpg"
```

Priority:

1. Active Storage attachment path (if attached)
2. OAuth provider URL (if no attachment)
3. `nil` (if neither available)

## Testing

Tests are included for:

- Active Storage avatar attachment
- Avatar downloading service
- User model avatar handling
- Avatar URL method behavior
- OAuth authentication flow with avatars

See:

- `spec/models/panda/core/user_spec.rb`
- `spec/services/panda/core/attach_avatar_service_spec.rb`

## Error Handling

The avatar service handles errors gracefully:

- Network failures during download
- File size limit exceeded (> 5MB)
- Invalid content types
- Timeout errors

Errors are logged but don't prevent user authentication. Users will fall back to initials-based avatars.

## Configuration

Avatar storage uses Active Storage, which is configured in `config/storage.yml`:

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

## Future Enhancements

Potential improvements:

- Image optimization/resizing on upload
- Support for user-uploaded avatars
- Avatar variants for different sizes
- Background job processing for avatar downloads
- CDN integration for serving avatars
