# Authentication Providers

Panda Core supports multiple authentication providers through OmniAuth.

## Available Providers

The following providers are supported:

- **Google** (`google_oauth2`)
- **Microsoft** (`microsoft_graph`) 
- **GitHub** (`github`)

## Configuration

### 1. Required Gems

Panda Core includes all necessary OAuth gems as dependencies, so you don't need to add them to your application's Gemfile.

### 2. Configure Credentials

Add your provider credentials to your Rails application's encrypted credentials file:

```bash
rails credentials:edit
```

```yaml
# For Google
google:
  client_id: your_client_id
  client_secret: your_client_secret

# For Microsoft  
microsoft:
  client_id: your_client_id
  client_secret: your_client_secret

# For GitHub
github:
  client_id: your_client_id
  client_secret: your_client_secret
```

### 3. Enable Providers

Configure providers in your panda_core initializer:

```ruby
# config/initializers/panda_core.rb
Panda::Core.configure do |config|
  config.authentication_providers = {
    # Google OAuth2
    google_oauth2: {
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: {
        # Optional: Restrict to specific domain
        hd: "yourdomain.com",
        prompt: "select_account"
      }
    },
    
    # Microsoft Graph
    microsoft_graph: {
      client_id: Rails.application.credentials.dig(:microsoft, :client_id),
      client_secret: Rails.application.credentials.dig(:microsoft, :client_secret),
      options: {
        skip_domain_verification: false,
        client_options: {
          site: "https://login.microsoftonline.com",
          authorize_url: "/common/oauth2/v2.0/authorize",
          token_url: "/common/oauth2/v2.0/token"
        }
      }
    },
    
    # GitHub
    github: {
      client_id: Rails.application.credentials.dig(:github, :client_id),
      client_secret: Rails.application.credentials.dig(:github, :client_secret),
      options: {
        scope: "user:email"
      }
    }
  }
end
```

## Provider Setup Guides

### Google OAuth2

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API
4. Navigate to Credentials → Create Credentials → OAuth 2.0 Client ID
5. Configure the OAuth consent screen
6. Add authorized redirect URIs:
   - Development: `http://localhost:3000/admin/auth/google_oauth2/callback`
   - Production: `https://your-app.com/admin/auth/google_oauth2/callback`

### Microsoft Azure

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to Azure Active Directory → App registrations
3. Click "New registration"
4. Configure:
   - Name: Your application name
   - Supported account types: Choose based on your needs
   - Redirect URI: Web platform
5. Add redirect URIs:
   - Development: `http://localhost:3000/admin/auth/microsoft_graph/callback`
   - Production: `https://your-app.com/admin/auth/microsoft_graph/callback`
6. Under Certificates & secrets, create a new client secret

### GitHub

1. Go to [GitHub Settings → Developer settings](https://github.com/settings/developers)
2. Click "New OAuth App"
3. Fill in:
   - Application name
   - Homepage URL
   - Authorization callback URL
4. Callback URLs:
   - Development: `http://localhost:3000/admin/auth/github/callback`
   - Production: `https://your-app.com/admin/auth/github/callback`

## Auto-provisioning Users

By default, Panda Core will:
- Create a new user on first successful OAuth login
- Make the first user in the system an admin
- Store the user's name, email, and profile image from OAuth

## Troubleshooting

### Common Issues

**Missing Provider Error**
```
undefined method 'google_oauth2' for OmniAuth::Builder
```
Solution: Ensure panda-core is properly installed with `bundle install`

**Invalid Credentials**
```
OAuth2::Error: invalid_client
```
Solution: Verify your client_id and client_secret in Rails credentials

**Redirect URI Mismatch**
```
The redirect URI in the request does not match
```
Solution: Ensure your OAuth provider has the exact callback URL configured

**Domain Restriction (Google)**
```
Invalid hosted domain
```
Solution: User's email domain doesn't match the `hd` parameter in configuration

### Debug Tips

1. Check Rails logs for detailed OAuth errors
2. Verify credentials with `rails credentials:show`
3. Test with development/test providers first
4. Use browser developer tools to inspect OAuth redirects

## Security Best Practices

1. **Always use HTTPS in production** - OAuth requires secure connections
2. **Rotate secrets regularly** - Update client secrets periodically
3. **Use domain restrictions** - Limit access to specific email domains when possible
4. **Monitor failed attempts** - Track authentication failures in logs
5. **Keep gems updated** - Ensure OAuth gems have latest security patches