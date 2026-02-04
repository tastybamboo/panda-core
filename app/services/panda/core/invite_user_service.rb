# frozen_string_literal: true

module Panda
  module Core
    class InviteUserService < Services::BaseService
      def initialize(email:, name:, invited_by:, admin: false)
        @email = email.to_s.downcase.strip
        @name = name.to_s.strip
        @invited_by = invited_by
        @admin = admin
      end

      def call
        return failure(["Email is required"]) if @email.blank?
        return failure(["Name is required"]) if @name.blank?

        existing_user = User.find_by(email: @email)
        return failure(["A user with this email already exists"]) if existing_user

        user = User.new(
          email: @email,
          name: @name,
          admin: @admin,
          enabled: true
        )

        unless user.save
          return failure(user.errors.full_messages)
        end

        user.invite!(invited_by: @invited_by)

        UserActivity.log!(
          user: @invited_by,
          action: "invited_user",
          resource: user,
          metadata: {invited_email: @email, admin: @admin}
        )

        success(user: user)
      end
    end
  end
end
