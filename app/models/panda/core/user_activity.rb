# frozen_string_literal: true

module Panda
  module Core
    class UserActivity < ApplicationRecord
      include HasUUID

      self.table_name = "panda_core_user_activities"

      belongs_to :user, class_name: "Panda::Core::User"

      validates :action, presence: true

      scope :recent, -> { order(created_at: :desc) }
      scope :for_user, ->(user) { where(user: user) }
      scope :by_action, ->(action) { where(action: action) }
      scope :today, -> { where(created_at: Time.current.beginning_of_day..) }
      scope :this_week, -> { where(created_at: Time.current.beginning_of_week..) }

      # Log a user activity with optional request context
      def self.log!(user:, action:, resource: nil, metadata: {}, request: nil)
        attrs = {
          user: user,
          action: action.to_s,
          metadata: metadata
        }

        if resource
          attrs[:resource_type] = resource.class.name
          attrs[:resource_id] = resource.id
        end

        if request
          attrs[:ip_address] = request.remote_ip
          attrs[:user_agent] = request.user_agent
        end

        create!(attrs)
      end
    end
  end
end
