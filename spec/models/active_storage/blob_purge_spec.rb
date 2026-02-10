# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ActiveStorage::Blob purge with FileCategorizations", type: :model do
  let!(:category) { Panda::Core::FileCategory.create!(name: "Test", slug: "purge-test") }
  let!(:blob) do
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: "purge_test.jpg",
      byte_size: 100,
      checksum: "abc",
      content_type: "image/jpeg"
    )
  end

  it "purges the blob and removes associated file categorizations" do
    Panda::Core::FileCategorization.create!(file_category: category, blob_id: blob.id)

    expect(Panda::Core::FileCategorization.where(blob_id: blob.id).count).to eq(1)

    blob.purge

    expect(ActiveStorage::Blob.exists?(blob.id)).to be false
    expect(Panda::Core::FileCategorization.where(blob_id: blob.id).count).to eq(0)
  end

  it "purges the blob when no file categorizations exist" do
    blob.purge

    expect(ActiveStorage::Blob.exists?(blob.id)).to be false
  end
end
