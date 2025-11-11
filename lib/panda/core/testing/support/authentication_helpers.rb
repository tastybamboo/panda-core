# frozen_string_literal: true

module Panda
  module Core
    module AuthenticationHelpers
      # Create test users with fixed IDs for consistent fixture references
      def create_admin_user
        Panda::Core::User.find_or_create_by!(id: "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a") do |user|
          user.email = "admin@test.example.com"
          user.firstname = "Admin"
          user.lastname = "User"
          user.admin = true
        end
      end

      def create_regular_user
        Panda::Core::User.find_or_create_by!(id: "9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d") do |user|
          user.email = "user@test.example.com"
          user.firstname = "Regular"
          user.lastname = "User"
          user.admin = false
        end
      end

      # For request specs - set session directly
      def sign_in_as(user)
        session[:user_id] = user.id
        Panda::Core::Current.user = user
      end

      # For system specs - use test session endpoint if available
      def login_as_admin
        admin_user = create_admin_user
        if defined?(Panda::CMS)
          # CMS provides test session endpoint
          post "/admin/test_sessions", params: {user_id: admin_user.id}
        else
          # Fall back to direct session setting
          sign_in_as(admin_user)
        end
      end

      def login_as_regular_user
        regular_user = create_regular_user
        if defined?(Panda::CMS)
          post "/admin/test_sessions", params: {user_id: regular_user.id}
        else
          sign_in_as(regular_user)
        end
      end
    end
  end
end

RSpec.configure do |config|
  # Include authentication helpers for all spec types (model, request, system, component, etc.)
  config.include Panda::Core::AuthenticationHelpers
end
