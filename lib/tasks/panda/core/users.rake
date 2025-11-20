# frozen_string_literal: true

namespace :panda do
  namespace :core do
    namespace :users do
      desc "List all users with their admin status"
      task list: :environment do
        users = Panda::Core::User.all.order(:email)

        if users.empty?
          puts "No users found."
        else
          puts "\nUsers:"
          puts "-" * 80
          users.each do |user|
            admin_badge = user.admin? ? "[ADMIN]" : ""
            puts "#{user.email.ljust(40)} #{admin_badge}"
          end
          puts "-" * 80
          puts "Total: #{users.count} (#{Panda::Core::User.admins.count} admins)"
        end
      end

      desc "Grant admin privileges to a user by email (EMAIL=user@example.com)"
      task grant_admin: :environment do
        email = ENV["EMAIL"]

        unless email
          puts "Error: EMAIL parameter is required"
          puts "Usage: rails panda:core:users:grant_admin EMAIL=user@example.com"
          exit 1
        end

        user = Panda::Core::User.find_by(email: email.downcase)

        unless user
          puts "Error: User with email '#{email}' not found"
          puts "\nExisting users:"
          Panda::Core::User.all.each do |u|
            puts "  - #{u.email}"
          end
          exit 1
        end

        if user.admin?
          puts "User '#{user.email}' is already an admin"
        else
          user.update!(is_admin: true)
          puts "✓ Granted admin privileges to '#{user.email}'"
        end
      end

      desc "Revoke admin privileges from a user by email (EMAIL=user@example.com)"
      task revoke_admin: :environment do
        email = ENV["EMAIL"]

        unless email
          puts "Error: EMAIL parameter is required"
          puts "Usage: rails panda:core:users:revoke_admin EMAIL=user@example.com"
          exit 1
        end

        user = Panda::Core::User.find_by(email: email.downcase)

        unless user
          puts "Error: User with email '#{email}' not found"
          exit 1
        end

        if user.admin?
          # Safety check: prevent revoking the last admin
          if Panda::Core::User.admins.count == 1
            puts "Error: Cannot revoke admin privileges from the last admin user"
            puts "Please create another admin first"
            exit 1
          end

          user.update!(is_admin: false)
          puts "✓ Revoked admin privileges from '#{user.email}'"
        else
          puts "User '#{user.email}' is not an admin"
        end
      end

      desc "Create a new admin user (EMAIL=user@example.com NAME='John Doe')"
      task create_admin: :environment do
        email = ENV["EMAIL"]
        name = ENV["NAME"] || "Admin User"

        unless email
          puts "Error: EMAIL parameter is required"
          puts "Usage: rails panda:core:users:create_admin EMAIL=user@example.com NAME='John Doe'"
          exit 1
        end

        existing_user = Panda::Core::User.find_by(email: email.downcase)

        if existing_user
          puts "Error: User with email '#{email}' already exists"
          if existing_user.admin?
            puts "This user is already an admin"
          else
            puts "Use 'rails panda:core:users:grant_admin EMAIL=#{email}' to make them an admin"
          end
          exit 1
        end

        # Build attributes hash based on schema
        user = Panda::Core::User.create!(
          email: email.downcase,
          name: name,
          is_admin: true
        )
        puts "✓ Created admin user '#{user.email}'"
        puts "  Name: #{user.name}" if user.respond_to?(:name)
        puts "  Admin: #{user.admin?}"
      end

      desc "Delete a user by email (EMAIL=user@example.com)"
      task delete: :environment do
        email = ENV["EMAIL"]

        unless email
          puts "Error: EMAIL parameter is required"
          puts "Usage: rails panda:core:users:delete EMAIL=user@example.com"
          exit 1
        end

        user = Panda::Core::User.find_by(email: email.downcase)

        unless user
          puts "Error: User with email '#{email}' not found"
          exit 1
        end

        # Safety check: prevent deleting the last admin
        if user.admin? && Panda::Core::User.admins.count == 1
          puts "Error: Cannot delete the last admin user"
          puts "Please create another admin first"
          exit 1
        end

        user.destroy!
        puts "✓ Deleted user '#{email}'"
      end
    end
  end
end
