require "rails_helper"

RSpec.describe Panda::Core::FileCategorization, type: :model do
  describe "associations" do
    it { should belong_to(:file_category).class_name("Panda::Core::FileCategory") }
    it { should belong_to(:blob).class_name("ActiveStorage::Blob") }
  end

  describe "validations" do
    let!(:category) { Panda::Core::FileCategory.create!(name: "Test", slug: "test") }
    let!(:blob) { ActiveStorage::Blob.create_before_direct_upload!(filename: "a.jpg", byte_size: 100, checksum: "abc", content_type: "image/jpeg") }
    subject { described_class.new(file_category: category, blob_id: blob.id) }

    it "validates uniqueness of file_category_id scoped to blob_id" do
      described_class.create!(file_category: category, blob_id: blob.id)
      duplicate = described_class.new(file_category: category, blob_id: blob.id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:file_category_id]).to include("has already been taken")
    end
  end

  describe "uniqueness constraint" do
    let!(:category) { Panda::Core::FileCategory.create!(name: "Test", slug: "test") }
    let!(:blob) { ActiveStorage::Blob.create_before_direct_upload!(filename: "a.jpg", byte_size: 100, checksum: "abc", content_type: "image/jpeg") }

    it "prevents duplicate categorizations" do
      described_class.create!(file_category: category, blob_id: blob.id)
      duplicate = described_class.new(file_category: category, blob_id: blob.id)
      expect(duplicate).not_to be_valid
    end

    it "allows same blob in different categories" do
      category2 = Panda::Core::FileCategory.create!(name: "Other", slug: "other")
      described_class.create!(file_category: category, blob_id: blob.id)
      expect(described_class.new(file_category: category2, blob_id: blob.id)).to be_valid
    end
  end
end
