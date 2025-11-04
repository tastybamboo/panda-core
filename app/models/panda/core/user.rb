# frozen_string_literal: true

module Panda
  module Core
    class User < ApplicationRecord
      self.table_name = "panda_core_users"

      validates :email, presence: true, uniqueness: {case_sensitive: false}

      before_save :downcase_email

      # Scopes
      scope :admins, -> { where(is_admin: true) }

      def self.find_or_create_from_auth_hash(auth_hash)
        user = find_by(email: auth_hash.info.email.downcase)
        return user if user

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

        create!(attributes)
      end

      def admin?
        is_admin
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
