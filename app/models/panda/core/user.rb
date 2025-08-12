# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      self.table_name = "panda_core_users"
      
      validates :email, presence: true, uniqueness: {case_sensitive: false}

      before_save :downcase_email
      
      # Scopes
      scope :admin, -> { where(admin: true) }

      def self.find_or_create_from_auth_hash(auth_hash)
        user = find_by(email: auth_hash.info.email.downcase)
        return user if user

        # Parse name into first and last
        full_name = auth_hash.info.name || "Unknown User"
        name_parts = full_name.split(" ", 2)
        
        create!(
          email: auth_hash.info.email.downcase,
          firstname: name_parts[0] || "Unknown",
          lastname: name_parts[1] || "",
          image_url: auth_hash.info.image,
          admin: User.count.zero? # First user is admin
        )
      end

      def admin?
        admin == true
      end
      
      def name
        "#{firstname} #{lastname}".strip
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
