# frozen_string_literal: true

module Panda
  module Core
    class Current < ActiveSupport::CurrentAttributes
      attribute :user, :request_id, :user_agent, :ip_address, :root, :page

      resets { Time.zone = nil }

      def user=(user)
        super
        Time.zone = user.try(:time_zone)
      end
    end
  end
end
