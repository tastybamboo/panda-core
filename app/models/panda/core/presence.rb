# frozen_string_literal: true

module Panda
  module Core
    class Presence < ApplicationRecord
      include HasUUID

      self.table_name = "panda_core_presences"

      belongs_to :presenceable, polymorphic: true
      belongs_to :user, class_name: "Panda::Core::User"

      validates :last_seen_at, presence: true

      scope :for_resource, ->(resource) {
        where(presenceable_type: resource.class.name, presenceable_id: resource.id)
      }
      scope :active, ->(ttl = 30.seconds) { where(last_seen_at: ttl.ago..) }
      scope :stale, ->(ttl = 30.seconds) { where(last_seen_at: ...ttl.ago) }
    end
  end
end
