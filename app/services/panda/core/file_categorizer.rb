# frozen_string_literal: true

module Panda
  module Core
    class FileCategorizer
      # Maps [record_type, attachment_name] to category slug
      ATTACHMENT_CATEGORY_MAP = {
        ["Panda::Core::User", "avatar"] => "user-avatars",
        ["Panda::CMS::Page", "og_image"] => "page-images",
        ["Panda::CMS::Post", "og_image"] => "post-images",
        ["Panda::CMS::FormSubmission", "files"] => "form-uploads",
        ["Panda::Social::InstagramPost", "image"] => "social-media"
      }.freeze

      # Categorize a blob by looking up its attachment's record type and name
      def categorize_attachment(attachment)
        slug = slug_for_attachment(attachment)
        return unless slug

        categorize_blob(attachment.blob, category_slug: slug)
      end

      # Directly assign a blob to a category by slug
      def categorize_blob(blob, category_slug:)
        category = Panda::Core::FileCategory.find_by(slug: category_slug)
        return unless category

        Panda::Core::FileCategorization.find_or_create_by!(
          file_category: category,
          blob_id: blob.id
        )
      end

      # Register additional mappings from other engines (e.g. panda-cms-pro)
      def self.register_mapping(record_type, attachment_name, category_slug)
        @custom_mappings ||= {}
        @custom_mappings[[record_type, attachment_name]] = category_slug
      end

      def self.custom_mappings
        @custom_mappings || {}
      end

      private

      def slug_for_attachment(attachment)
        key = [attachment.record_type, attachment.name]
        ATTACHMENT_CATEGORY_MAP[key] || self.class.custom_mappings[key]
      end
    end
  end
end
