# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      self.table_name = "panda_core_users"

      validates :email, presence: true, uniqueness: {case_sensitive: false}

      before_save :downcase_email

      def self.find_or_create_from_auth_hash(auth_hash)
        user = find_by(email: auth_hash.info.email.downcase)
        return user if user

        # Parse name into first and last
        full_name = auth_hash.info.name || "Unknown User"
        
        create!(
          email: auth_hash.info.email.downcase,
          name: full_name,
          image_url: auth_hash.info.image,
          is_admin: User.count.zero? # First user is admin
        )
      end

      def admin?
        is_admin == true
      end

      def active_for_authentication?
        true
      end

      private

      def downcase_email
        self.email = email.downcase if email.present?
      end
    end
  end
end
