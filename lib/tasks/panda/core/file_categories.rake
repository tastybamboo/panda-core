# frozen_string_literal: true

namespace :panda do
  namespace :core do
    namespace :file_categories do
      desc "Seed default file categories"
      task seed: [:environment] do
        require "panda/core/seeds/file_categories"
        Panda::Core::Seeds::FileCategories.seed!
        puts "Default file categories seeded."
      end

      desc "Categorize existing blobs based on their attachments"
      task categorize_existing: [:environment] do
        require "panda/core/seeds/file_categories"
        Panda::Core::Seeds::FileCategories.seed!

        categorizer = Panda::Core::FileCategorizer.new
        categorized = 0
        skipped = 0

        ActiveStorage::Blob.find_each do |blob|
          if Panda::Core::FileCategorization.exists?(blob_id: blob.id)
            skipped += 1
            next
          end

          attachment = ActiveStorage::Attachment.where(blob_id: blob.id).first
          if attachment
            categorizer.categorize_attachment(attachment)
          else
            categorizer.categorize_blob(blob, category_slug: "media-library")
          end
          categorized += 1
        end

        puts "Categorized #{categorized} blobs, skipped #{skipped} already-categorized."
      end
    end
  end
end
