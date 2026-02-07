# frozen_string_literal: true

module Panda
  module Core
    class PresenceService
      def self.record_presence(resource, user_id)
        attrs = {
          presenceable_type: resource.class.name,
          presenceable_id: resource.id,
          user_id: user_id
        }

        result = Presence.upsert(
          attrs.merge(last_seen_at: Time.current),
          unique_by: %i[presenceable_type presenceable_id user_id],
          returning: %w[id]
        )

        record_id = result.first&.fetch("id") { raise "Upsert did not return an ID" }
        Presence.find(record_id)
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
          .active(Presence::PRESENCE_TTL)
          .includes(:user)
          .map do |presence|
            {
              user_id: presence.user_id,
              user_name: presence.user.name.presence || presence.user.email
            }
          end
      end

      def self.cleanup_stale!
        Presence.stale(Presence::PRESENCE_TTL).delete_all
      end
    end
  end
end
