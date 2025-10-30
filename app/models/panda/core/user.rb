# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      self.table_name = "panda_core_users"

      validates :email, presence: true, uniqueness: {case_sensitive: false}

      before_save :downcase_email

      # Scopes
      scope :admin, -> { where(is_admin: true) }

      def self.find_or_create_from_auth_hash(auth_hash)
        user = find_by(email: auth_hash.info.email.downcase)
        return user if user

        create!(
          email: auth_hash.info.email.downcase,
          name: auth_hash.info.name || "Unknown User",
          image_url: auth_hash.info.image,
          is_admin: User.count.zero? # First user is admin
        )
      end

      def admin?
        is_admin?
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

      private

      def downcase_email
        self.email = email.downcase if email.present?
      end
    end
  end
end
