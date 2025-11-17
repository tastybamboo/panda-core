# frozen_string_literal: true

# Comprehensive authentication test helpers for Panda Core and consuming gems
# This module provides helpers for:
# - Creating test users with fixed IDs
# - OAuth mocking and configuration
# - Test session management
# - Request and system test authentication

module Panda
  module Core
    module AuthenticationTestHelpers
      # ============================================================================
      # USER CREATION HELPERS
      # ============================================================================

      # Create an admin user with fixed ID for consistent fixture references
      def create_admin_user(attributes = {})
        ensure_columns_loaded
        admin_id = "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a"
        Panda::Core::User.find_or_create_by!(id: admin_id) do |user|
          user.email = attributes[:email] || "admin@example.com"
          user.firstname = attributes[:firstname] || "Admin" if user.respond_to?(:firstname=)
          user.lastname = attributes[:lastname] || "User" if user.respond_to?(:lastname=)
          user.name = attributes[:name] || "Admin User" if user.respond_to?(:name=) && !user.respond_to?(:firstname=)
          user.image_url = attributes[:image_url] || default_image_url if user.respond_to?(:image_url=)
          # Use is_admin for the actual column, but support both for compatibility
          if user.respond_to?(:is_admin=)
            user.is_admin = attributes.fetch(:admin, true)
          elsif user.respond_to?(:admin=)
            user.admin = attributes.fetch(:admin, true)
          end
          # Only set OAuth fields if they exist on the model
          user.uid = attributes[:uid] || "admin_oauth_uid_123" if user.respond_to?(:uid=)
          user.provider = attributes[:provider] || "google_oauth2" if user.respond_to?(:provider=)
        end
      end

      # Create a regular user with fixed ID for consistent fixture references
      def create_regular_user(attributes = {})
        ensure_columns_loaded
        regular_id = "9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d"
        Panda::Core::User.find_or_create_by!(id: regular_id) do |user|
          user.email = attributes[:email] || "user@example.com"
          user.firstname = attributes[:firstname] || "Regular" if user.respond_to?(:firstname=)
          user.lastname = attributes[:lastname] || "User" if user.respond_to?(:lastname=)
          user.name = attributes[:name] || "Regular User" if user.respond_to?(:name=) && !user.respond_to?(:firstname=)
          user.image_url = attributes[:image_url] || default_image_url(dark: true) if user.respond_to?(:image_url=)
          # Use is_admin for the actual column, but support both for compatibility
          if user.respond_to?(:is_admin=)
            user.is_admin = attributes.fetch(:admin, false)
          elsif user.respond_to?(:admin=)
            user.admin = attributes.fetch(:admin, false)
          end
          # Only set OAuth fields if they exist on the model
          user.uid = attributes[:uid] || "user_oauth_uid_456" if user.respond_to?(:uid=)
          user.provider = attributes[:provider] || "google_oauth2" if user.respond_to?(:provider=)
        end
      end

      # Backwards compatibility with fixture access patterns
      def admin_user
        ensure_columns_loaded
        @admin_user ||= Panda::Core::User.find_by(email: "admin@example.com") || create_admin_user
      end

      def regular_user
        ensure_columns_loaded
        @regular_user ||= Panda::Core::User.find_by(email: "user@example.com") || create_regular_user
      end

      # ============================================================================
      # OMNIAUTH HELPERS
      # ============================================================================

      def clear_omniauth_config
        OmniAuth.config.mock_auth.clear
        Rails.application.env_config.delete("omniauth.auth") if defined?(Rails.application)
      end

      def mock_oauth_for_user(user, provider: :google_oauth2)
        clear_omniauth_config
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
          provider: provider.to_s,
          uid: (user.respond_to?(:uid) ? user.uid : nil) || user.id,
          info: {
            email: user.email,
            name: user.name,
            image: user.respond_to?(:image_url) ? user.image_url : nil
          },
          credentials: {
            token: "mock_token_#{user.id}",
            expires_at: Time.now + 1.week
          }
        })
      end

      # ============================================================================
      # REQUEST SPEC HELPERS (Direct Session Manipulation)
      # ============================================================================

      # For request specs - set session directly (fast, no HTTP requests)
      def sign_in_as(user)
        # This works in request specs where we have direct access to the session
        begin
          if respond_to?(:session)
            session[:user_id] = user.id
          end
        rescue NoMethodError
          # Session method doesn't exist in this context (e.g., system specs)
        end
        Panda::Core::Current.user = user
        user
      end

      # ============================================================================
      # SYSTEM SPEC HELPERS (HTTP-based Authentication)
      # ============================================================================

      # For system specs - use test session endpoint (works across processes)
      # This uses the TestSessionsController which is only available in test environment
      #
      # NOTE: Due to Cuprite's redirect handling, we visit the target path directly
      # after setting up the session via the test endpoint. Flash messages won't be
      # available in system tests due to cross-process timing. Use request specs
      # to test flash messages (see authentication_request_spec.rb).
      def login_with_test_endpoint(user, return_to: nil, expect_success: true)
        return_path = return_to || determine_default_redirect_path

        # Visit the test login endpoint (sets session via Redis)
        # Note: Capybara/Cuprite may not follow the redirect properly, so we
        # manually navigate to the expected destination
        visit "/admin/test_login/#{user.id}?return_to=#{return_path}"

        # Wait briefly for session to be set
        # sleep 0.2

        # Manually visit the destination since Cuprite doesn't reliably follow redirects
        if expect_success
          visit return_path
          # Wait for page to load
          # sleep 0.2

          # Verify we're on the expected path
          expect(page).to have_current_path(return_path, wait: 2)
        end
      end

      # Convenience method: Login with Google OAuth provider (using test endpoint)
      def login_with_google(user, expect_success: true)
        login_with_test_endpoint(user, return_to: determine_default_redirect_path, expect_success: expect_success)
      end

      # Convenience method: Login with GitHub OAuth provider (using test endpoint)
      def login_with_github(user, expect_success: true)
        login_with_test_endpoint(user, return_to: determine_default_redirect_path, expect_success: expect_success)
      end

      # Convenience method: Login with Microsoft OAuth provider (using test endpoint)
      def login_with_microsoft(user, expect_success: true)
        login_with_test_endpoint(user, return_to: determine_default_redirect_path, expect_success: expect_success)
      end

      # High-level helper: Login as admin (creates user if needed)
      # This method is idempotent - calling it multiple times is safe
      def login_as_admin(attributes = {})
        user = create_admin_user(attributes)
        if respond_to?(:visit)
          # System spec - check if already logged in to avoid navigation pollution
          return user if already_logged_in_as_admin?

          # System spec - use test endpoint
          login_with_test_endpoint(user, expect_success: true)
        else
          # Request spec - use direct session
          sign_in_as(user)
        end
        user
      end

      # High-level helper: Login as regular user (creates user if needed)
      # This method is idempotent - calling it multiple times is safe
      def login_as_user(attributes = {})
        user = create_regular_user(attributes)
        if respond_to?(:visit)
          # System spec - check if already logged in to avoid navigation pollution
          return user if already_logged_in_as_admin?

          # System spec - regular users get redirected to login
          login_with_test_endpoint(user, expect_success: false)
        else
          # Request spec - use direct session
          sign_in_as(user)
        end
        user
      end

      # Manual OAuth login (slower, but tests actual OAuth flow)
      # Use this when you need to test the OAuth callback handler itself
      def manual_login_with_oauth(user, provider: :google_oauth2)
        mock_oauth_for_user(user, provider: provider)

        visit admin_login_path
        expect(page).to have_css("#button-sign-in-#{provider}")
        find("#button-sign-in-#{provider}").click

        Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[provider]
      end

      # ============================================================================
      # PRIVATE HELPER METHODS
      # ============================================================================

      private

      # Check if already logged in as admin to avoid unnecessary navigation
      # This prevents test pollution from multiple login attempts
      def already_logged_in_as_admin?
        return false unless respond_to?(:page)

        begin
          # Check if we're already on an admin page (indicates active session)
          current_path = begin
            page.current_path
          rescue
            nil
          end
          return false if current_path.nil? || current_path == "" || current_path == "/"

          # If we're on an admin path and can access it, we're logged in
          if current_path.start_with?("/admin")
            # Try to detect if page has admin content (not a login page)
            return false if current_path.include?("/login")
            return true if page.has_css?("body", wait: 0.5)
          end

          false
        rescue
          # If we can't check the page state, assume not logged in
          false
        end
      end

      def ensure_columns_loaded
        return if @columns_loaded
        Panda::Core::User.connection.schema_cache.clear!
        Panda::Core::User.reset_column_information
        @columns_loaded = true
      end

      def default_image_url(dark: false)
        color = dark ? "%23999" : "%23ccc"
        "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='#{color}'/%3E%3C/svg%3E"
      end

      def determine_default_redirect_path
        # Check if we're in a CMS context
        if defined?(Panda::CMS)
          "/admin/cms"
        else
          "/admin"
        end
      end

      def admin_login_path
        if defined?(panda_core)
          panda_core.admin_login_path
        else
          "/admin/login"
        end
      end

      def admin_root_path
        if defined?(panda_core)
          panda_core.admin_root_path
        else
          "/admin"
        end
      end
    end
  end
end

# Configure RSpec to include these helpers in appropriate test types
RSpec.configure do |config|
  config.include Panda::Core::AuthenticationTestHelpers, type: :request
  config.include Panda::Core::AuthenticationTestHelpers, type: :system
  config.include Panda::Core::AuthenticationTestHelpers, type: :controller
end

# Configure OmniAuth for testing
OmniAuth.config.test_mode = true
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
