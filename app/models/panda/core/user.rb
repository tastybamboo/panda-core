# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      include HasUUID

      self.table_name = "panda_core_users"

      # Associations
      has_many :user_activities, class_name: "Panda::Core::UserActivity", dependent: :destroy
      has_many :user_sessions, class_name: "Panda::Core::UserSession", dependent: :destroy
      belongs_to :invited_by, class_name: "Panda::Core::User", optional: true

      # Active Storage attachment for avatar with variants
      has_one_attached :avatar do |attachable|
        attachable.variant :thumb, resize_to_limit: [50, 50], preprocessed: true
        attachable.variant :small, resize_to_limit: [100, 100], preprocessed: true
        attachable.variant :medium, resize_to_limit: [200, 200], preprocessed: true
        attachable.variant :large, resize_to_limit: [400, 400], preprocessed: true
      end

      validates :email, presence: true, uniqueness: {case_sensitive: false}

      before_save :downcase_email

      # Determine which column stores admin flag (supports legacy `admin` and new `is_admin`)
      def self.admin_column
        # Prefer canonical `admin` if available, otherwise fall back to legacy `is_admin`
        @admin_column ||= column_names.include?("admin") ? "admin" : "is_admin"
      end

      # Scopes
      scope :admins, -> {
        where(admin_column => true)
      }
      scope :enabled, -> { where(enabled: true) }
      scope :disabled, -> { where(enabled: false) }
      scope :invited, -> { where.not(invitation_token: nil).where(invitation_accepted_at: nil) }
      scope :active_recently, -> { where(last_login_at: 30.days.ago..) }
      scope :search, ->(query) {
        return all if query.blank?
        where("name ILIKE :q OR email ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
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
          :email => auth_hash.info.email.downcase,
          :name => auth_hash.info.name || "Unknown User",
          :image_url => auth_hash.info.image,
          admin_column => User.count.zero? # First user is admin
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
        ActiveRecord::Type::Boolean.new.cast(admin)
      end

      # Support both legacy `admin` and new `is_admin` columns
      def admin
        self[self.class.admin_column]
      end

      def admin=(value)
        self[self.class.admin_column] = ActiveRecord::Type::Boolean.new.cast(value)
      end
      alias_method :is_admin, :admin
      alias_method :is_admin=, :admin=

      def active_for_authentication?
        enabled?
      end

      def enable!
        update!(enabled: true)
      end

      def disable!
        update!(enabled: false)
      end

      def enabled?
        self[:enabled] != false
      end

      def invite!(invited_by:)
        update!(
          invitation_token: SecureRandom.urlsafe_base64(32),
          invitation_sent_at: Time.current,
          invited_by: invited_by
        )
      end

      def accept_invitation!
        update!(
          invitation_accepted_at: Time.current,
          invitation_token: nil
        )
      end

      def track_login!(request)
        update!(
          last_login_at: Time.current,
          last_login_ip: request.remote_ip,
          login_count: (login_count || 0) + 1
        )
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
