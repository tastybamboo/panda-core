# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      include HasUUID
      include HasMetadata

      metadata_field :internal, type: :boolean, filterable: true,
        label: "Visibility", default_scope: :external,
        filter_options: [["All Users", ""], ["Staff Users", "internal"], ["External Users", "external"]]

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
        # Email is the cross-provider identity key, so we must only trust it
        # when the identity provider actually attests the user owns it.
        # Otherwise a provider that lets a user assert an arbitrary email
        # (a generic OAuth2/OIDC/SAML strategy, or a misconfigured one) would
        # allow matching into an existing account — an account-takeover vector.
        unless email_verified_for_auth?(auth_hash)
          user = new(
            email: auth_hash.info.email.to_s.downcase,
            name: auth_hash.info.name || "Unknown User"
          )
          user.errors.add(:base, "Your email address could not be verified with the identity provider. Please contact your administrator.")
          return user
        end

        user = find_by(email: auth_hash.info.email.downcase)

        avatar_url = auth_hash.info.image
        if user
          has_stored_avatar = begin
            user.avatar.attached?
          rescue
            false
          end

          if avatar_url.present?
            # Update image_url with latest OAuth URL only if no local avatar is stored
            user.update_column(:image_url, avatar_url) unless has_stored_avatar

            # Skip OAuth avatar download when user has a manually uploaded avatar
            # (indicated by oauth_avatar_url being nil while an avatar is attached)
            manually_uploaded = has_stored_avatar && user.oauth_avatar_url.nil?
            unless manually_uploaded
              # Try to download and store avatar if URL changed or no avatar attached
              if avatar_url != user.oauth_avatar_url || !has_stored_avatar
                AttachAvatarService.call(user: user, avatar_url: avatar_url)
              end
            end
          end
          return user
        end

        # Check if user creation is restricted (e.g. invite-only mode)
        restrict = Panda::Core.config.restrict_user_creation
        restricted = restrict.respond_to?(:call) ? restrict.call(auth_hash) : restrict
        if restricted
          user = new(email: auth_hash.info.email.downcase, name: auth_hash.info.name || "Unknown User")
          user.errors.add(:base, "No account exists for this email address. Please contact your administrator.")
          return user
        end

        attributes = {
          :email => auth_hash.info.email.downcase,
          :name => auth_hash.info.name || "Unknown User",
          :image_url => avatar_url,
          admin_column => User.count.zero? # First user is admin
        }

        user = create!(attributes)

        # Attach avatar for new user (will clear image_url on success)
        if avatar_url.present?
          AttachAvatarService.call(user: user, avatar_url: avatar_url)
        end

        user
      end

      # Whether the provider's asserted email may be trusted as proof of
      # ownership for this authentication.
      #
      # Precedence:
      #   1. An explicit `email_verified` signal from the provider (checked in
      #      both `info` and `extra.raw_info`) is authoritative — truthy means
      #      verified, an explicit false means NOT verified (no fallback).
      #   2. When the provider returns no such signal, fall back to the
      #      `trusted_email_providers` allow-list so operators must opt a
      #      provider in. The dev-only `developer` strategy is trusted only in
      #      the development environment.
      def self.email_verified_for_auth?(auth_hash)
        signal = extract_email_verified_signal(auth_hash)
        return truthy_verification?(signal) unless signal.nil?

        provider = indifferent_lookup(auth_hash, :provider).to_s
        return false if provider.empty?
        return true if provider == "developer" && Rails.env.development?

        trusted = Panda::Core.config.trusted_email_providers || []
        trusted.map(&:to_s).include?(provider)
      end

      # Pull an `email_verified` value from the standard OmniAuth locations.
      # Returns nil when the provider asserts nothing (so the caller can fall
      # back to the trust policy), and preserves an explicit `false`.
      def self.extract_email_verified_signal(auth_hash)
        info = indifferent_lookup(auth_hash, :info)
        info_signal = indifferent_lookup(info, :email_verified)
        return info_signal unless info_signal.nil?

        extra = indifferent_lookup(auth_hash, :extra)
        raw_info = indifferent_lookup(extra, :raw_info)
        indifferent_lookup(raw_info, :email_verified)
      end

      # OmniAuth strategies variously return booleans or strings ("true").
      def self.truthy_verification?(value)
        value == true || value.to_s.strip.casecmp("true").zero?
      end

      # Fetch a key from an OmniAuth::AuthHash (Hashie::Mash) or a plain Hash
      # without losing an explicit `false` value. Returns nil when absent.
      def self.indifferent_lookup(hash, key)
        return nil unless hash.respond_to?(:key?)

        if hash.key?(key.to_s)
          hash[key.to_s]
        elsif hash.key?(key.to_sym)
          hash[key.to_sym]
        end
      end

      private_class_method :email_verified_for_auth?, :extract_email_verified_signal,
        :truthy_verification?, :indifferent_lookup

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
        return self[:image_url].presence unless avatar.attached?

        helpers = Rails.application.routes.url_helpers
        if size && [:thumb, :small, :medium, :large].include?(size)
          helpers.rails_representation_path(avatar.variant(size), only_path: true)
        else
          helpers.rails_blob_path(avatar.blob, only_path: true)
        end
      rescue => e
        Rails.logger.error("Error generating avatar URL for user #{id}: #{e.message}\n#{e.backtrace&.first(3)&.join("\n")}")
        self[:image_url].presence
      end

      private

      def downcase_email
        self.email = email.downcase if email.present?
      end
    end
  end
end
