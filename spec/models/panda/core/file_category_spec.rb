require "rails_helper"

RSpec.describe Panda::Core::FileCategory, type: :model do
  describe "validations" do
    subject { described_class.new(name: "Test Category", slug: "test-category") }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }

    it "requires slug when name is blank" do
      category = described_class.new(name: nil, slug: nil)
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to include("can't be blank")
    end

    it "rejects slugs with invalid characters" do
      category = described_class.new(name: "Test", slug: "Invalid Slug!")
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to include("must contain only lowercase letters, numbers, and hyphens")
    end

    it "accepts valid slugs" do
      category = described_class.new(name: "Test", slug: "valid-slug-123")
      expect(category).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:parent).class_name("Panda::Core::FileCategory").optional }
    it { should have_many(:children).class_name("Panda::Core::FileCategory") }
    it { should have_many(:file_categorizations).class_name("Panda::Core::FileCategorization") }
    it { should have_many(:blobs).through(:file_categorizations) }
  end

  describe "slug generation" do
    it "auto-generates slug from name when blank" do
      category = described_class.create!(name: "Page Images")
      expect(category.slug).to eq("page-images")
    end

    it "does not overwrite an explicitly set slug" do
      category = described_class.create!(name: "Page Images", slug: "custom-slug")
      expect(category.slug).to eq("custom-slug")
    end
  end

  describe "scopes" do
    let!(:root_category) { described_class.create!(name: "Root", slug: "root", position: 0) }
    let!(:child_category) { described_class.create!(name: "Child", slug: "child", parent: root_category, position: 1) }
    let!(:system_category) { described_class.create!(name: "System", slug: "system", system: true, position: 2) }

    describe ".roots" do
      it "returns only top-level categories" do
        expect(described_class.roots).to include(root_category, system_category)
        expect(described_class.roots).not_to include(child_category)
      end
    end

    describe ".system_categories" do
      it "returns only system categories" do
        expect(described_class.system_categories).to include(system_category)
        expect(described_class.system_categories).not_to include(root_category)
      end
    end

    describe ".custom_categories" do
      it "returns only non-system categories" do
        expect(described_class.custom_categories).to include(root_category, child_category)
        expect(described_class.custom_categories).not_to include(system_category)
      end
    end

    describe ".ordered" do
      it "orders by position then name" do
        expect(described_class.ordered.to_a).to eq([root_category, child_category, system_category])
      end
    end
  end

  describe "#all_blob_ids" do
    let!(:parent) { described_class.create!(name: "Parent", slug: "parent") }
    let!(:child) { described_class.create!(name: "Child", slug: "child", parent: parent) }
    let!(:blob1) { ActiveStorage::Blob.create_before_direct_upload!(filename: "a.jpg", byte_size: 100, checksum: "abc", content_type: "image/jpeg") }
    let!(:blob2) { ActiveStorage::Blob.create_before_direct_upload!(filename: "b.jpg", byte_size: 200, checksum: "def", content_type: "image/jpeg") }

    before do
      Panda::Core::FileCategorization.create!(file_category: parent, blob_id: blob1.id)
      Panda::Core::FileCategorization.create!(file_category: child, blob_id: blob2.id)
    end

    it "includes blob IDs from both parent and children" do
      expect(parent.all_blob_ids).to contain_exactly(blob1.id, blob2.id)
    end

    it "includes only own blob IDs for child categories" do
      expect(child.all_blob_ids).to contain_exactly(blob2.id)
    end
  end

  describe "system category protection" do
    let!(:system_category) { described_class.create!(name: "System", slug: "sys", system: true) }

    it "prevents deletion of system categories" do
      expect { system_category.destroy }.not_to change(described_class, :count)
      expect(system_category.errors[:base]).to include("System categories cannot be deleted")
    end
  end
end
