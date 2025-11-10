Panda::Core::Engine.routes.draw do
  # Get admin_path from configuration
  # Default to "/admin" if not yet configured
  admin_path = (Panda::Core.config.admin_path || "/admin").delete_prefix("/")

  scope path: admin_path, as: "admin" do
    get "/login", to: "admin/sessions#new", as: :login

    # OmniAuth routes - middleware handles /admin/auth/:provider automatically
    # We just need to define the callback routes
    get "/auth/:provider/callback", to: "admin/sessions#create", as: :auth_callback
    post "/auth/:provider/callback", to: "admin/sessions#create"
    get "/auth/failure", to: "admin/sessions#failure", as: :auth_failure
    delete "/logout", to: "admin/sessions#destroy", as: :logout

    # Dashboard and admin routes - authentication handled by AdminController
    get "/", to: "admin/dashboard#show", as: :root

    # Profile management
    resource :my_profile, only: %i[show edit update], controller: "admin/my_profile", path: "my_profile"

    # Test-only authentication endpoint (available in development and test environments)
    # This bypasses OAuth for faster, more reliable test execution
    # Development: Used by Capybara system tests which run Rails server in development mode
    # Test: Used by controller/request tests
    unless Rails.env.production?
      get "/test_login/:user_id", to: "admin/test_sessions#create", as: :test_login
      post "/test_sessions", to: "admin/test_sessions#create", as: :test_sessions

      # Test routes for nested navigation feature testing
      scope :team, as: :team do
        get "overview", to: "admin/team/test_pages#overview"
        get "members", to: "admin/team/test_pages#members"
        get "calendar", to: "admin/team/test_pages#calendar"
        get "settings", to: "admin/team/test_pages#settings"
      end

      scope :projects, as: :projects do
        get "/", to: "admin/projects/test_pages#index"
        get "active", to: "admin/projects/test_pages#active"
        get "archived", to: "admin/projects/test_pages#archived"
      end
    end
  end
end
