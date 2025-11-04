# Quick Start: Authentication Testing

Get started with Panda Core's authentication test helpers in 5 minutes.

## Setup (One-Time)

Add this to your gem's `spec/rails_helper.rb`:

```ruby
# Load Panda Core's test helpers
panda_core_support_path = Gem.loaded_specs["panda-core"]&.full_gem_path
if panda_core_support_path
  Dir[File.join(panda_core_support_path, "spec/support/**/*.rb")].sort.each { |f| require f }
end
```

That's it! The helpers are now available in all your tests.

## Common Patterns

### Pattern 1: Test Protected Endpoint (Request Spec)

```ruby
RSpec.describe "Admin Widgets", type: :request do
  it "requires admin login" do
    get "/admin/widgets"

    expect(response).to redirect_to(admin_login_path)
  end

  it "allows admin access" do
    sign_in_as(create_admin_user)  # ← Magic happens here

    get "/admin/widgets"

    expect(response).to have_http_status(:success)
  end
end
```

### Pattern 2: Test Flash Messages (Request Spec)

```ruby
RSpec.describe "Authentication", type: :request do
  it "shows error for invalid user" do
    post "/admin/test_sessions", params: {user_id: "invalid"}

    # Flash testing works perfectly in request specs!
    expect(flash[:error]).to eq("User not found")
    expect(response).to redirect_to(admin_login_path)
  end
end
```

### Pattern 3: Test User Workflow (System Spec)

```ruby
RSpec.describe "Widget Management", type: :system do
  it "allows admin to create widget" do
    # Login via test endpoint
    admin = create_admin_user
    visit "/admin/test_login/#{admin.id}"
    sleep 0.3  # Brief wait for session

    # Test the workflow
    visit "/admin/widgets"
    click_button "New Widget"
    fill_in "Name", with: "My Widget"
    click_button "Create"

    expect(page).to have_content("My Widget")
  end
end
```

### Pattern 4: Test Admin vs Regular User Access

```ruby
RSpec.describe "Admin Pages", type: :request do
  let(:admin) { create_admin_user }
  let(:user) { create_regular_user }

  describe "GET /admin/pages" do
    it "allows admin" do
      sign_in_as(admin)
      get "/admin/pages"
      expect(response).to have_http_status(:success)
    end

    it "denies regular user" do
      sign_in_as(user)
      get "/admin/pages"
      expect(response).to redirect_to(admin_login_path)
      expect(flash[:error]).to eq("You do not have permission to access the admin area")
    end
  end
end
```

## Helper Cheat Sheet

### Creating Users

```ruby
admin = create_admin_user                    # Default admin
admin = create_admin_user(email: "me@...")  # Custom attributes
user = create_regular_user                   # Non-admin user

# Memoized versions (creates once, reuses)
admin_user      # First call creates, subsequent calls reuse
regular_user    # First call creates, subsequent calls reuse
```

### Logging In (Request/Controller Specs)

```ruby
sign_in_as(user)         # Sets session directly (fast!)
sign_in_as(admin_user)  # Works with any user
```

### Logging In (System Specs)

```ruby
# Direct endpoint visit (simple, recommended)
visit "/admin/test_login/#{user.id}"
sleep 0.3

# Or use convenience helpers
login_with_google(user)
login_with_github(user)
login_with_microsoft(user)
login_as_admin  # Creates admin and logs in
```

### OAuth Mocking (Advanced)

```ruby
# Mock OAuth for testing real OAuth flow
clear_omniauth_config
mock_oauth_for_user(user, provider: :google_oauth2)

# Then test OAuth callback
post "/admin/auth/google_oauth2/callback",
  env: {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}
```

## Quick Troubleshooting

### "undefined method `create_admin_user`"
→ Add Panda Core support files to `rails_helper.rb` (see Setup above)

### Flash messages don't appear in system tests
→ ✅ Use **request specs** for flash testing, not system specs

### Session not working in system tests
→ Use Redis session store in test environment

### Tests are slow
→ Use request specs instead of system specs where possible

## Real-World Examples

### Testing a CRUD Controller

```ruby
RSpec.describe Admin::PostsController, type: :request do
  let(:admin) { create_admin_user }
  let(:valid_params) { {post: {title: "Test", body: "Content"}} }

  before { sign_in_as(admin) }

  describe "POST /admin/posts" do
    it "creates post with flash" do
      expect {
        post "/admin/posts", params: valid_params
      }.to change(Post, :count).by(1)

      expect(flash[:success]).to eq("Post created successfully")
      expect(response).to redirect_to(admin_posts_path)
    end

    it "shows error on invalid params" do
      post "/admin/posts", params: {post: {title: ""}}

      expect(flash[:error]).to be_present
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
```

### Testing Authorization

```ruby
RSpec.describe "Admin Authorization", type: :request do
  let(:admin) { create_admin_user }
  let(:user) { create_regular_user }
  let(:endpoints) { ["/admin/pages", "/admin/posts", "/admin/settings"] }

  describe "admin access" do
    before { sign_in_as(admin) }

    it "allows access to all admin endpoints" do
      endpoints.each do |endpoint|
        get endpoint
        expect(response).not_to redirect_to(admin_login_path)
      end
    end
  end

  describe "regular user access" do
    before { sign_in_as(user) }

    it "denies access to all admin endpoints" do
      endpoints.each do |endpoint|
        get endpoint
        expect(response).to redirect_to(admin_login_path)
      end
    end
  end
end
```

### Testing Multi-Step Workflow

```ruby
RSpec.describe "Content Publishing Workflow", type: :system do
  it "allows admin to create and publish post" do
    admin = create_admin_user
    visit "/admin/test_login/#{admin.id}"
    sleep 0.3

    # Step 1: Create draft
    visit "/admin/posts/new"
    fill_in "Title", with: "My Post"
    fill_in "Body", with: "Content here"
    click_button "Save Draft"
    expect(page).to have_content("Draft saved")

    # Step 2: Edit draft
    click_link "Edit"
    fill_in "Title", with: "My Updated Post"
    click_button "Save Draft"
    expect(page).to have_content("Draft updated")

    # Step 3: Publish
    click_button "Publish"
    expect(page).to have_content("Post published")

    # Verify published state
    post = Post.last
    expect(post.published?).to be true
    expect(post.title).to eq("My Updated Post")
  end
end
```

## Next Steps

- **Full Guide**: Read [Authentication Test Helpers Guide](../testing/authentication-helpers.md)
- **Architecture**: Understand the [Authentication System Architecture](../architecture/authentication-system.md)
- **Flash Testing**: Deep dive into [Flash Message Testing](../../../cms/docs/testing/flash-message-testing.md)
- **Examples**: Browse `panda-core/spec/requests/panda/core/admin/sessions_spec.rb`

## Quick Reference Card

```ruby
# SETUP (rails_helper.rb)
panda_core_support_path = Gem.loaded_specs["panda-core"]&.full_gem_path
Dir[File.join(panda_core_support_path, "spec/support/**/*.rb")].each { |f| require f } if panda_core_support_path

# CREATE USERS
admin = create_admin_user
user = create_regular_user

# REQUEST SPECS (✅ Flash testing works!)
sign_in_as(admin)
get "/admin/widgets"
expect(flash[:success]).to eq("...")

# SYSTEM SPECS (User workflows, no flash)
visit "/admin/test_login/#{admin.id}"
sleep 0.3
visit "/admin"
expect(page).to have_content("Dashboard")
```

Happy testing! 🎉
