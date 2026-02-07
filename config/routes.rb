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
    resource :my_profile, only: %i[show edit update], controller: "admin/my_profile", path: "my_profile" do
      resource :logins, only: [:show], controller: "admin/my_profile/logins"
    end

    # Settings
    resource :settings, only: [:show], controller: "admin/settings"

    # User management
    resources :users, only: %i[index show edit update], controller: "admin/users" do
      member do
        patch :enable
        patch :disable
        get :activity
        get :sessions
        delete "sessions/:session_id", action: :revoke_session, as: :revoke_session
      end
      collection do
        post :invite
        post :bulk_action
      end
    end

    # File category management
    resources :file_categories, only: %i[index new create edit update destroy], controller: "admin/file_categories"

    # Test-only authentication endpoint (available in development and test environments)
    # This bypasses OAuth for faster, more reliable test execution
    # Development: Used by Capybara system tests which run Rails server in development mode
    # Test: Used by controller/request tests
    if Rails.env.development? || Rails.env.test?
      get "/test_login/:user_id", to: "admin/test_sessions#create", as: :test_login
      post "/test_sessions", to: "admin/test_sessions#create", as: :test_sessions
    end
  end
end
