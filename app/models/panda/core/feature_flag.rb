# frozen_string_literal: true

module Panda
  module Core
    class FeatureFlag < ApplicationRecord
      self.table_name = "panda_core_feature_flags"

      validates :key, presence: true, uniqueness: true

      # Check whether a feature flag is enabled.
      # Returns false for unknown keys (safe default).
      # Results are cached for 1 minute to avoid repeated DB lookups.
      def self.enabled?(key)
        Rails.cache.fetch(cache_key_for(key), expires_in: 1.minute) do
          where(key: key, enabled: true).exists?
        end
      end

      # Enable a feature flag by key.
      def self.enable!(key)
        flag = find_by!(key: key)
        flag.update!(enabled: true)
        Rails.cache.write(cache_key_for(key), true, expires_in: 1.minute)
      end

      # Disable a feature flag by key.
      def self.disable!(key)
        flag = find_by!(key: key)
        flag.update!(enabled: false)
        Rails.cache.write(cache_key_for(key), false, expires_in: 1.minute)
      end

      # Toggle a feature flag by key.
      def self.toggle!(key)
        flag = find_by!(key: key)
        flag.update!(enabled: !flag.enabled)
        Rails.cache.write(cache_key_for(key), flag.enabled, expires_in: 1.minute)
      end

      # Register a feature flag idempotently.
      # Only sets description and enabled on initial creation — existing
      # flags keep their current state so admin changes are preserved.
      def self.register(key, description: nil, enabled: false)
        find_or_create_by(key: key) do |flag|
          flag.description = description
          flag.enabled = enabled
        end
      end

      def self.cache_key_for(key)
        "panda_core:feature_flag:#{key}"
      end
      private_class_method :cache_key_for
    end
  end
end
