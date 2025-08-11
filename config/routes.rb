Panda::Core::Engine.routes.draw do
  # Use the configured admin path (defaults to "/admin")
  admin_path = Panda::Core.configuration.admin_path.delete_prefix("/")
  
  scope path: admin_path, as: "admin" do
    get "/login", to: "admin/sessions#new", as: :login
    
    # OmniAuth routes - middleware handles /admin/auth/:provider automatically
    # We just need to define the callback routes
    get "/auth/:provider/callback", to: "admin/sessions#create", as: :auth_callback
    post "/auth/:provider/callback", to: "admin/sessions#create"
    get "/auth/failure", to: "admin/sessions#failure", as: :auth_failure
    delete "/logout", to: "admin/sessions#destroy", as: :logout

    constraints Panda::Core::AdminConstraint.new do
      get "/", to: "admin/dashboard#show", as: :root
      
      # Profile management
      resource :my_profile, only: %i[edit update], controller: "admin/my_profile", path: "my_profile"
    end
  end
end
