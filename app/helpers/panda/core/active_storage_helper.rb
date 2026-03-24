# frozen_string_literal: true

module Panda
  module Core
    module ActiveStorageHelper
      # Generates a URL for an ActiveStorage variant, compatible with both Rails 7.x and 8.1+.
      #
      # In Rails 8.1+, both url_for(variant) and image_tag(variant) break because
      # VariantWithRecord no longer implements to_model. This helper constructs the
      # representation proxy path directly from the blob and variation, avoiding
      # all polymorphic routing that relies on to_model.
      #
      # @param variant [ActiveStorage::VariantWithRecord] The variant to generate a URL for
      # @return [String, nil] The URL path, or nil if generation fails
      def variant_representation_url(variant)
        blob = variant.blob
        "/rails/active_storage/representations/proxy/#{blob.signed_id}/#{variant.variation.key}/#{blob.filename}"
      rescue => e
        Rails.logger.warn "[Panda] Failed to generate variant URL (#{e.class}): #{e.message}"
        nil
      end
    end
  end
end
