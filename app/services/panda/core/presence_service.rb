# frozen_string_literal: true

module Panda
  module Core
    class PresenceService
      PRESENCE_TTL = 30.seconds

      def self.record_presence(resource, user_id)
        presence = Presence.find_or_initialize_by(
          presenceable_type: resource.class.name,
          presenceable_id: resource.id,
          user_id: user_id
        )
        presence.update!(last_seen_at: Time.current)
        presence
      end

      def self.remove_presence(resource, user_id)
        Presence.where(
          presenceable_type: resource.class.name,
          presenceable_id: resource.id,
          user_id: user_id
        ).delete_all
      end

      def self.current_editors(resource)
        Presence
          .for_resource(resource)
          .active(PRESENCE_TTL)
          .includes(:user)
          .map do |presence|
            {
              user_id: presence.user_id,
              user_name: presence.user.name.presence || presence.user.email
            }
          end
      end

      def self.cleanup_stale!
        Presence.stale(PRESENCE_TTL).delete_all
      end
    end
  end
end
