# Authentication in Panda Core

Panda Core provides a flexible authentication system built on OmniAuth that is used by all Panda ecosystem gems.

## Overview

The authentication system in Panda Core:
- Provides OAuth-based authentication (no passwords)
- Supports multiple providers (Google, Microsoft, GitHub)
- Manages user sessions and permissions
- Auto-provisions users on first login (configurable)

## Topics

1. [Authentication Providers](providers.md)
   - Available providers
   - Configuration and setup
   - Troubleshooting
   - Security considerations

2. [Migration Guide](migration.md)
   - Migrating from panda-cms authentication
   - Database changes
   - Configuration updates

## Quick Start

1. Install panda-core in your application
2. Run migrations to create the users table
3. Configure your authentication providers
4. Users can now authenticate via OAuth

Example configuration:

```ruby
# config/initializers/panda_core.rb
Panda::Core.configure do |config|
  config.authentication_providers = {
    google_oauth2: {
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: {}
    },
    github: {
      client_id: Rails.application.credentials.dig(:github, :client_id),
      client_secret: Rails.application.credentials.dig(:github, :client_secret),
      options: {}
    }
  }
end
```

## User Model

The `Panda::Core::User` model provides:
- OAuth authentication handling
- Admin status management (`is_admin` field)
- Auto-provisioning on first login
- Name and email storage

## Integration with Panda CMS

When using Panda CMS with Panda Core:
1. Authentication is handled entirely by Panda Core
2. Panda CMS uses the `Panda::Core::User` model
3. Admin routes are protected using Core's authentication
4. Sessions are managed by Core

## Best Practices

1. **Security**
   - Always use HTTPS in production
   - Keep credentials in Rails encrypted credentials
   - Use environment-specific configurations

2. **User Experience**
   - Enable appropriate providers for your audience
   - Consider auto-provisioning settings
   - Provide clear login instructions

3. **Maintenance**
   - Keep provider gems updated
   - Monitor authentication logs
   - Test authentication flows regularly