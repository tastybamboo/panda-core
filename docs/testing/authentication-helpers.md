# Authentication Test Helpers Guide

This guide explains how to use Panda Core's authentication test helpers in your Panda gem projects.

## Overview

Panda Core provides comprehensive test helpers for authentication that work across different test types:
- **Request Specs**: Direct session manipulation (fast, reliable)
- **System Specs**: HTTP-based authentication via test endpoint (cross-process)
- **Controller Specs**: Direct session access

## Installation

The helpers are automatically available when you include Panda Core's spec support files in your `rails_helper.rb`:

```ruby
# In your gem's spec/rails_helper.rb

# Load Panda::Core support files (authentication helpers, etc.)
panda_core_support_path = Gem.loaded_specs["panda-core"]&.full_gem_path
if panda_core_support_path
  Dir[File.join(panda_core_support_path, "spec/support/**/*.rb")].sort.each { |f| require f }
end
```

## Available Helpers

### User Creation Helpers

```ruby
# Create an admin user with fixed ID (useful for fixture references)
admin = create_admin_user

# Create with custom attributes
admin = create_admin_user(email: "custom@example.com", name: "Custom Name")

# Create a regular (non-admin) user
user = create_regular_user

# Backwards compatibility accessors
admin = admin_user        # Creates or finds admin
user = regular_user       # Creates or finds regular user
```

### OAuth Mocking Helpers

```ruby
# Clear OmniAuth configuration (useful in before blocks)
clear_omniauth_config

# Mock OAuth for a specific user
mock_oauth_for_user(user, provider: :google_oauth2)
mock_oauth_for_user(user, provider: :github)
mock_oauth_for_user(user, provider: :microsoft_graph)
```

## Usage by Test Type

### Request Specs (RECOMMENDED for Flash Messages)

Request specs run in-process and can directly access the session and flash:

```ruby
RSpec.describe "Admin Dashboard", type: :request do
  let(:admin) { create_admin_user }
  let(:regular_user) { create_regular_user }

  describe "GET /admin" do
    context "when not logged in" do
      it "redirects to login" do
        get "/admin"

        expect(response).to redirect_to(admin_login_path)
        expect(flash[:error]).to eq("Please log in to continue")
      end
    end

    context "when logged in as admin" do
      before { sign_in_as(admin) }

      it "shows the dashboard" do
        get "/admin"

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Dashboard")
      end
    end

    context "when logged in as regular user" do
      before { sign_in_as(regular_user) }

      it "denies access" do
        get "/admin"

        expect(response).to redirect_to(admin_login_path)
        expect(flash[:error]).to eq("You do not have permission to access the admin area")
      end
    end
  end
end
```

**Key Method**: `sign_in_as(user)` - Sets session directly (fast, no HTTP requests)

### System Specs (for User Workflows)

System specs test the full application stack with a browser. Use the test endpoint for cross-process authentication:

```ruby
RSpec.describe "Admin Dashboard", type: :system do
  let(:admin) { create_admin_user }

  it "allows admin to access dashboard" do
    # Use test endpoint to set session (works across processes with Redis)
    visit "/admin/test_login/#{admin.id}"
    # sleep 0.3  # Brief wait for session to be set

    # Navigate to protected page
    visit "/admin"

    # Verify access granted
    expect(page).not_to have_current_path("/admin/login")
    expect(page).to have_content("Dashboard")
  end

  it "prevents regular user access" do
    regular_user = create_regular_user
    visit "/admin/test_login/#{regular_user.id}"
    # sleep 0.3

    # Should be redirected to login
    expect(page).to have_current_path("/admin/login")
  end
end
```

**Key Methods**:
- `login_with_google(user, expect_success: true)` - Login via Google (uses test endpoint)
- `login_with_github(user, expect_success: true)` - Login via GitHub
- `login_with_microsoft(user, expect_success: true)` - Login via Microsoft
- `login_as_admin` - High-level helper (creates admin and logs in)

**Important Note**: Due to Cuprite's redirect handling, system tests may have timing issues. For testing flash messages, **use request specs instead**.

### Controller Specs

```ruby
RSpec.describe Admin::PagesController, type: :controller do
  let(:admin) { create_admin_user }

  describe "GET #index" do
    context "when logged in as admin" do
      before { sign_in_as(admin) }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(admin_login_path)
      end
    end
  end
end
```

## Flash Message Testing

**✅ DO**: Test flash messages in **request specs**

```ruby
RSpec.describe "Authentication", type: :request do
  it "sets flash on failed login" do
    post "/admin/test_sessions", params: {user_id: "nonexistent"}

    # Direct flash access works in request specs!
    expect(flash[:error]).to eq("User not found")
    expect(response).to redirect_to(admin_login_path)
  end
end
```

**❌ DON'T**: Rely on flash messages in system specs

```ruby
# This may fail due to cross-process timing
RSpec.describe "Authentication", type: :system do
  it "shows flash on failed login" do
    visit "/admin/test_login/invalid_user_id"
    # ❌ Flash may not appear due to cross-process timing
    expect(page).to have_content("User not found")  # Unreliable
  end
end
```

**Why?** Flash messages are cleared after being read once. In system tests, the server process may read/clear the flash before your test can assert on it.

## Test Endpoint Security

The test session endpoint (`/admin/test_login/:user_id` and `POST /admin/test_sessions`) is **only available in test environment**:

```ruby
# In panda-core/config/routes.rb
if Rails.env.test?
  get "/test_login/:user_id", to: "admin/test_sessions#create"
  post "/test_sessions", to: "admin/test_sessions#create"
end
```

This controller is never loaded in production, providing an additional safety layer.

## Complete Example: Testing a Protected Resource

```ruby
# spec/requests/your_gem/admin/widgets_spec.rb
RSpec.describe "Admin Widgets", type: :request do
  let(:admin) { create_admin_user }
  let(:regular_user) { create_regular_user }

  describe "GET /admin/widgets" do
    context "when logged in as admin" do
      before { sign_in_as(admin) }

      it "lists widgets" do
        get "/admin/widgets"

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Widgets")
      end
    end

    context "when logged in as regular user" do
      before { sign_in_as(regular_user) }

      it "denies access with flash message" do
        get "/admin/widgets"

        expect(response).to redirect_to(admin_login_path)
        expect(flash[:error]).to eq("You do not have permission to access the admin area")
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get "/admin/widgets"

        expect(response).to redirect_to(admin_login_path)
        expect(flash[:notice]).to eq("Please log in to continue")
      end
    end
  end

  describe "POST /admin/widgets" do
    let(:valid_params) { {widget: {name: "Test Widget"}} }

    context "when logged in as admin" do
      before { sign_in_as(admin) }

      it "creates widget with success flash" do
        expect {
          post "/admin/widgets", params: valid_params
        }.to change(Widget, :count).by(1)

        expect(flash[:success]).to eq("Widget created successfully")
        expect(response).to redirect_to(admin_widgets_path)
      end
    end
  end
end
```

## System Test Example: User Workflow

```ruby
# spec/system/your_gem/admin/widget_management_spec.rb
RSpec.describe "Widget Management", type: :system do
  let(:admin) { create_admin_user }

  it "allows admin to manage widgets" do
    # Login via test endpoint
    visit "/admin/test_login/#{admin.id}"
    # sleep 0.3

    # Navigate to widgets
    visit "/admin/widgets"

    # Verify we can access the page
    expect(page).to have_content("Widgets")
    expect(page).not_to have_current_path("/admin/login")

    # Perform actions
    click_button "New Widget"
    fill_in "Name", with: "Test Widget"
    click_button "Create"

    # Verify outcome (don't rely on flash)
    expect(page).to have_content("Test Widget")
  end
end
```

## Troubleshooting

### "undefined method `create_admin_user`"

**Solution**: Ensure you've loaded Panda Core's support files in `rails_helper.rb` (see Installation section).

### Flash messages not appearing in system tests

**Solution**: Use request specs to test flash messages. System tests have cross-process timing issues that make flash testing unreliable.

### Session not persisting across requests in system tests

**Solution**: Ensure you're using Redis for session storage in your test environment:

```ruby
# config/environments/test.rb
config.session_store :redis_store, {
  servers: ["redis://localhost:6379/1/session"],
  expire_after: 90.minutes,
  key: "_your_app_session_test"
}
```

### Tests are slow

**Solution**: Use request specs instead of system specs where possible. Request specs are much faster because they don't require a browser.

## Best Practices

1. ✅ Use **request specs** for testing authentication logic and flash messages
2. ✅ Use **system specs** for testing complete user workflows
3. ✅ Create users with `create_admin_user` for consistent IDs
4. ✅ Use `sign_in_as(user)` in request/controller specs (fast)
5. ✅ Use test endpoint (`/admin/test_login/:user_id`) in system specs
6. ❌ Don't test flash messages in system specs
7. ❌ Don't use OAuth mock setup in system tests (use test endpoint instead)

## Related Documentation

- [Flash Message Testing Guide](../../../cms/docs/testing/flash-message-testing.md) (in panda-cms)
- [Request Specs in RSpec](https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec)
- [System Tests in Rails](https://guides.rubyonrails.org/testing.html#system-testing)

## Support

If you encounter issues with these helpers, please:
1. Check this documentation
2. Review the examples in `panda-core/spec/requests/panda/core/admin/sessions_spec.rb`
3. Open an issue in the Panda Core repository
