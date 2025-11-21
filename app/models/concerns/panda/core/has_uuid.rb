# frozen_string_literal: true

module Panda
  module Core
    # Concern for models using UUIDs as primary keys
    # Ensures UUID generation works across all database adapters
    module HasUUID
      extend ActiveSupport::Concern

      included do
        # Generate UUID before creation if not already set
        # PostgreSQL uses gen_random_uuid() natively
        # SQLite and other databases use SecureRandom.uuid
        before_create :generate_uuid_if_blank
      end

      private

      def generate_uuid_if_blank
        self.id ||= SecureRandom.uuid if id.blank?
      end
    end
  end
end
