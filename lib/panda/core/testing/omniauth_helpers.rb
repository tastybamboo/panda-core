# frozen_string_literal: true

module Panda
  module Core
    module Testing
      module OmniAuthHelpers
        def mock_omniauth_login(email: "admin@example.com", name: "Test User", provider: :google_oauth2, uid: "123456789", is_admin: true)
          OmniAuth.config.test_mode = true
          OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
            provider: provider.to_s,
            uid: uid,
            info: {
              email: email,
              name: name,
              image: "https://example.com/avatar.jpg"
            }
          )

          # Create or update the user in the test database
          Panda::Core::User.find_or_create_by(email: email) do |u|
            # Split name into firstname and lastname
            parts = name.split(' ', 2)
            u.firstname = parts[0] || name
            u.lastname = parts[1] || ''
            u.admin = is_admin
          end
        end

        def login_as_admin(email: "admin@example.com", name: "Admin User")
          user = mock_omniauth_login(email: email, name: name, is_admin: true)
          visit "/admin/auth/google_oauth2"
          user
        end

        def login_as_user(email: "user@example.com", name: "Regular User")
          user = mock_omniauth_login(email: email, name: name, is_admin: false)
          visit "/admin/auth/google_oauth2"
          user
        end

        def logout
          visit "/admin/logout"
        end

        def mock_omniauth_failure(message = "Authentication failed")
          OmniAuth.config.test_mode = true
          OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
        end
      end
    end
  end
end
