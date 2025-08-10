# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      self.table_name = "panda_core_users"

      validates :email, presence: true, uniqueness: {case_sensitive: false}
      validates :firstname, presence: true
      validates :lastname, presence: true

      before_save :downcase_email

      def self.find_or_create_from_auth_hash(auth_hash)
        user = find_by(email: auth_hash.info.email.downcase)
        return user if user

        # Split name on first space
        name_parts = (auth_hash.info.name || 'Unknown User').split(' ', 2)
        
        create!(
          email: auth_hash.info.email.downcase,
          firstname: name_parts[0] || 'Unknown',
          lastname: name_parts[1] || '',
          image_url: auth_hash.info.image,
          admin: User.count.zero? # First user is admin
        )
      end

      # Virtual attribute for full name
      def name
        "#{firstname} #{lastname}".strip
      end
      
      def name=(value)
        parts = value.to_s.split(' ', 2)
        self.firstname = parts[0] || ''
        self.lastname = parts[1] || ''
      end
      
      def admin?
        admin
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