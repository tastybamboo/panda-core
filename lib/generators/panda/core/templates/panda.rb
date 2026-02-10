# frozen_string_literal: true

Panda::Core.configure do |config|
  # Path prefix for admin routes (e.g. "/admin", "/manage")
  config.admin_path = "/admin"

  # Title shown on the login page
  config.login_page_title = "Admin"

  # Title shown in the admin navigation bar
  config.admin_title = "<%= Rails.application.class.module_parent_name %> Admin"

  # Authentication providers
  # Add the corresponding OmniAuth gem for each provider you enable
  # (e.g. omniauth-google-oauth2, omniauth-github, omniauth-microsoft_graph).
  #
  # In development, GitHub OAuth works out of the box with shared dev credentials
  # (restricted to localhost:3000). For production, add your own credentials via
  # `rails credentials:edit`.
  #
  # The "developer" provider is built into OmniAuth and only active in
  # development — it shows a simple form to enter a name and email.
  #
  # config.authentication_providers = {
  #   github: {
  #     enabled: true,
  #     name: "GitHub",
  #     client_id: if Rails.env.development?
  #                  "Ov23liFMGyVvRrpuvyTT" # Shared Panda dev app (localhost:3000 only)
  #                else
  #                  Rails.application.credentials.dig(:github, :client_id)
  #                end,
  #     client_secret: if Rails.env.development?
  #                      "394a7024d7dd9c0ee0c8540768331d59d9e22477"
  #                    else
  #                      Rails.application.credentials.dig(:github, :client_secret)
  #                    end
  #   },
  #   developer: {
  #     enabled: true,
  #     name: "Developer Login"
  #   }
  # }

  # Session cookie name
  config.session_token_cookie = :panda_session

  # User model classes (usually left as defaults)
  config.user_class = "Panda::Core::User"
  config.user_identity_class = "Panda::Core::UserIdentity"
end

# Uncomment after adding gem "panda-cms" to your Gemfile:
# Panda::CMS.configure do |config|
#   # Require login to view the public site
#   config.require_login_to_view = false
# end

# Uncomment after adding gem "panda-editor" to your Gemfile:
# Panda::Editor.configure do |config|
#   # Additional EditorJS tools to load
#   # config.editor_js_tools = []
# end
