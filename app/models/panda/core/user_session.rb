# frozen_string_literal: true

module Panda
  module Core
    class UserSession < ApplicationRecord
      include HasUUID

      self.table_name = "panda_core_user_sessions"

      belongs_to :user, class_name: "Panda::Core::User"
      belongs_to :revoked_by, class_name: "Panda::Core::User", optional: true

      validates :session_id, presence: true, uniqueness: true

      scope :active_sessions, -> { where(active: true, revoked_at: nil) }
      scope :for_user, ->(user) { where(user: user) }
      scope :recent, -> { order(last_active_at: :desc) }

      # Revoke a session (e.g. admin force-logout)
      def revoke!(admin:)
        update!(
          active: false,
          revoked_at: Time.current,
          revoked_by: admin
        )
      end

      # Update last activity timestamp
      def touch_activity!
        update!(last_active_at: Time.current)
      end
    end
  end
end
