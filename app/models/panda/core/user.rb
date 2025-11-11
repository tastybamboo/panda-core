# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      self.table_name = "panda_core_users"

      # Active Storage attachment for avatar with variants
      has_one_attached :avatar do |attachable|
        attachable.variant :thumb, resize_to_limit: [50, 50], preprocessed: true
        attachable.variant :small, resize_to_limit: [100, 100], preprocessed: true
        attachable.variant :medium, resize_to_limit: [200, 200], preprocessed: true
        attachable.variant :large, resize_to_limit: [400, 400], preprocessed: true
      end

      validates :email, presence: true, uniqueness: {case_sensitive: false}

      before_save :downcase_email

      # Scopes
      # Support both 'admin' (newer) and 'is_admin' (older) column names
      scope :admins, -> {
        if column_names.include?("admin")
          where(admin: true)
        elsif column_names.include?("is_admin")
          where(is_admin: true)
        else
          none
        end
      }

      def self.find_or_create_from_auth_hash(auth_hash)
        user = find_by(email: auth_hash.info.email.downcase)

        # Handle avatar for both new and existing users
        avatar_url = auth_hash.info.image
        if user
          # Update avatar if URL has changed or no avatar is attached
          if avatar_url.present? && (avatar_url != user.oauth_avatar_url || !user.avatar.attached?)
            AttachAvatarService.call(user: user, avatar_url: avatar_url)
          end
          return user
        end

        # Support both schema versions: 'name' column or 'firstname'/'lastname' columns
        attributes = {
          email: auth_hash.info.email.downcase,
          image_url: auth_hash.info.image,
          is_admin: User.count.zero? # First user is admin
        }

        # Add name attributes based on schema
        if column_names.include?("name")
          attributes[:name] = auth_hash.info.name || "Unknown User"
        elsif column_names.include?("firstname") && column_names.include?("lastname")
          # Split name into firstname/lastname if provided
          full_name = auth_hash.info.name || "Unknown User"
          name_parts = full_name.split(" ", 2)
          attributes[:firstname] = name_parts[0] || "Unknown"
          attributes[:lastname] = name_parts[1] || "User"
        end

        user = create!(attributes)

        # Attach avatar for new user
        if avatar_url.present?
          AttachAvatarService.call(user: user, avatar_url: avatar_url)
        end

        user
      end

      # Admin status check
      # Note: Column is named 'admin' in newer schemas, 'is_admin' in older ones
      def admin?
        self[:admin] || self[:is_admin] || false
      end

      def active_for_authentication?
        true
      end

      def name
        # Support both schema versions:
        # - Main app: has 'name' column
        # - Test app: has 'firstname' and 'lastname' columns
        if respond_to?(:firstname) && respond_to?(:lastname)
          "#{firstname} #{lastname}".strip
        elsif self[:name].present?
          self[:name]
        else
          email&.split("@")&.first || "Unknown User"
        end
      end

      # Returns the URL for the user's avatar
      # Prefers Active Storage attachment over OAuth provider URL
      # @param size [Symbol] The variant size (:thumb, :small, :medium, :large, or nil for original)
      # @return [String, nil] The avatar URL or nil if no avatar available
      def avatar_url(size: nil)
        if avatar.attached?
          if size && [:thumb, :small, :medium, :large].include?(size)
            Rails.application.routes.url_helpers.rails_blob_path(avatar.variant(size), only_path: true)
          else
            Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true)
          end
        elsif self[:image_url].present?
          # Fallback to OAuth provider URL if no avatar is attached yet
          self[:image_url]
        end
      end

      private

      def downcase_email
        self.email = email.downcase if email.present?
      end
    end
  end
end
