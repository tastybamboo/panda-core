require "rails_helper"

RSpec.describe Panda::Core::FileCategorizer do
  subject(:categorizer) { described_class.new }

  let!(:media_library) { Panda::Core::FileCategory.create!(name: "Media Library", slug: "media-library", system: true) }
  let!(:page_images) { Panda::Core::FileCategory.create!(name: "Page Images", slug: "page-images", system: true) }
  let!(:user_avatars) { Panda::Core::FileCategory.create!(name: "User Avatars", slug: "user-avatars", system: true) }

  let!(:blob) { ActiveStorage::Blob.create_before_direct_upload!(filename: "test.jpg", byte_size: 100, checksum: "abc", content_type: "image/jpeg") }

  describe "#categorize_blob" do
    it "creates a categorization for the given blob and category slug" do
      expect {
        categorizer.categorize_blob(blob, category_slug: "media-library")
      }.to change(Panda::Core::FileCategorization, :count).by(1)

      categorization = Panda::Core::FileCategorization.last
      expect(categorization.file_category).to eq(media_library)
      expect(categorization.blob_id).to eq(blob.id)
    end

    it "is idempotent - does not create duplicates" do
      categorizer.categorize_blob(blob, category_slug: "media-library")
      expect {
        categorizer.categorize_blob(blob, category_slug: "media-library")
      }.not_to change(Panda::Core::FileCategorization, :count)
    end

    it "returns nil when category slug does not exist" do
      result = categorizer.categorize_blob(blob, category_slug: "nonexistent")
      expect(result).to be_nil
    end
  end

  describe "#categorize_attachment" do
    it "maps Panda::CMS::Page og_image to page-images" do
      attachment = instance_double(
        ActiveStorage::Attachment,
        record_type: "Panda::CMS::Page",
        name: "og_image",
        blob: blob
      )

      categorizer.categorize_attachment(attachment)

      categorization = Panda::Core::FileCategorization.last
      expect(categorization.file_category).to eq(page_images)
    end

    it "maps Panda::Core::User avatar to user-avatars" do
      attachment = instance_double(
        ActiveStorage::Attachment,
        record_type: "Panda::Core::User",
        name: "avatar",
        blob: blob
      )

      categorizer.categorize_attachment(attachment)

      categorization = Panda::Core::FileCategorization.last
      expect(categorization.file_category).to eq(user_avatars)
    end

    it "does nothing for unknown attachment types" do
      attachment = instance_double(
        ActiveStorage::Attachment,
        record_type: "SomeUnknown::Model",
        name: "document",
        blob: blob
      )

      expect {
        categorizer.categorize_attachment(attachment)
      }.not_to change(Panda::Core::FileCategorization, :count)
    end
  end

  describe ".register_mapping" do
    after { described_class.instance_variable_set(:@custom_mappings, nil) }

    it "allows external engines to register custom mappings" do
      custom_category = Panda::Core::FileCategory.create!(name: "Custom", slug: "custom-cat", system: true)

      described_class.register_mapping("Custom::Model", "files", "custom-cat")

      attachment = instance_double(
        ActiveStorage::Attachment,
        record_type: "Custom::Model",
        name: "files",
        blob: blob
      )

      categorizer.categorize_attachment(attachment)
      expect(Panda::Core::FileCategorization.last.file_category).to eq(custom_category)
    end
  end
end
