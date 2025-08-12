# Migration Guide: From Panda CMS to Panda Core Authentication

This guide helps you migrate from the legacy Panda CMS authentication system to the new Panda Core authentication.

## Overview of Changes

### What's Changed

1. **Authentication moved to Panda Core**
   - User model: `Panda::CMS::User` → `Panda::Core::User`
   - Table name: `panda_cms_users` → `panda_core_users`
   - Configuration: Now in `Panda::Core` instead of `Panda::CMS`

2. **Database Schema Changes**
   - `firstname` + `lastname` → `name` (single field)
   - `admin` → `is_admin` (renamed boolean)
   - Table moved to panda-core migrations

3. **Configuration Location**
   - Old: `Panda::CMS.configure`
   - New: `Panda::Core.configure`

## Migration Steps

### Step 1: Update Dependencies

Update your Gemfile to use the new versions:

```ruby
# Gemfile
gem 'panda-core', '~> 0.2.0'  # or latest version
gem 'panda-cms', '~> 0.8.0'   # or latest version
```

Run bundle update:
```bash
bundle update panda-core panda-cms
```

### Step 2: Run Migration

Panda CMS includes an automatic migration that will:
1. Copy existing users from `panda_cms_users` to `panda_core_users`
2. Update foreign key references
3. Drop the old table

```bash
# Install panda-core migrations
rails panda_core:install:migrations

# Run the migration
rails db:migrate
```

The migration handles:
- Combining firstname/lastname into name field
- Renaming admin to is_admin
- Updating all foreign key references

### Step 3: Update Configuration

Move authentication configuration from Panda CMS to Panda Core:

**Old configuration (remove this):**
```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  config.authentication = {
    google: {
      enabled: true,
      client_id: "...",
      client_secret: "..."
    }
  }
end
```

**New configuration (add this):**
```ruby
# config/initializers/panda_core.rb
Panda::Core.configure do |config|
  config.authentication_providers = {
    google_oauth2: {
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: {}
    }
  }
end
```

### Step 4: Update Your Code

If you have custom code referencing the User model:

**Old:**
```ruby
user = Panda::CMS::User.find_by(email: "user@example.com")
full_name = "#{user.firstname} #{user.lastname}"
is_admin = user.admin
```

**New:**
```ruby
user = Panda::Core::User.find_by(email: "user@example.com")
full_name = user.name
is_admin = user.is_admin
```

### Step 5: Update Tests

Update test fixtures and specs:

**Old fixture:**
```yaml
# spec/fixtures/panda_cms_users.yml
admin_user:
  firstname: "Admin"
  lastname: "User"
  admin: true
```

**New fixture:**
```yaml
# spec/fixtures/panda_core_users.yml
admin_user:
  name: "Admin User"
  is_admin: true
```

Update fixture references in specs:
```ruby
# Old
fixtures :panda_cms_users

# New
fixtures :panda_core_users
```

## Rollback Instructions

If you need to rollback the migration:

```bash
rails db:rollback
```

This will:
1. Recreate the `panda_cms_users` table
2. Copy data back from `panda_core_users`
3. Restore foreign key references

## Troubleshooting

### Foreign Key Errors

If you see errors like:
```
PG::ForeignKeyViolation: ERROR: insert or update on table "panda_cms_posts" 
violates foreign key constraint
```

Solution: The migration should handle this automatically, but if it doesn't:
1. Check that the migration ran successfully
2. Verify foreign keys point to `panda_core_users`

### Missing User Attributes

If you get errors about missing `firstname` or `lastname`:
```
NoMethodError: undefined method 'firstname' for Panda::Core::User
```

Solution: Update your code to use the new `name` field instead.

### Authentication Not Working

If users can't log in after migration:
1. Verify `panda_core_users` table has data
2. Check that `Panda::Core` is configured with providers
3. Ensure OAuth callback URLs haven't changed

## Compatibility

- **Backward Compatibility**: The migration maintains all user data
- **Forward Compatibility**: New installations use Panda Core auth by default
- **Data Integrity**: All user associations are preserved during migration

## Need Help?

If you encounter issues during migration:
1. Check the Rails logs for detailed error messages
2. Ensure all gems are updated to compatible versions
3. Report issues on GitHub with migration error details