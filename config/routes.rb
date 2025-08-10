Panda::Core::Engine.routes.draw do
  scope path: "/admin", as: "admin" do
    get "/login", to: "admin/sessions#new", as: :login
    get "/auth/:provider/callback", to: "admin/sessions#create", as: :auth_callback
    delete "/logout", to: "admin/sessions#destroy", as: :logout

    constraints Panda::Core::AdminConstraint.new do
      get "/", to: "admin/dashboard#index", as: :root
    end
  end
end
