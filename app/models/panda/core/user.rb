# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      include HasUUID

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
      scope :admins, -> {
        where(admin: true)
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

        attributes = {
          email: auth_hash.info.email.downcase,
          name: auth_hash.info.name || "Unknown User",
          image_url: auth_hash.info.image,
          admin: User.count.zero? # First user is admin
        }

        user = create!(attributes)

        # Attach avatar for new user
        if avatar_url.present?
          AttachAvatarService.call(user: user, avatar_url: avatar_url)
        end

        user
      end

      # Admin status check
      def admin?
        admin
      end

      def active_for_authentication?
        true
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
