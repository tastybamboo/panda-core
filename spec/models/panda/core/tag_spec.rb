# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Tag, type: :model do
  describe "associations" do
    it { should belong_to(:tenant).optional }
    it { should have_many(:taggings).class_name("Panda::Core::Tagging").dependent(:destroy) }
  end

  describe "validations" do
    subject { described_class.new(name: "Test Tag") }

    it { should validate_presence_of(:name) }

    it "validates uniqueness of name scoped to tenant" do
      described_class.create!(name: "Unique Tag", tenant_type: nil, tenant_id: nil)
      duplicate = described_class.new(name: "unique tag", tenant_type: nil, tenant_id: nil)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "allows the same name for different tenants" do
      described_class.create!(name: "Shared Tag", tenant_type: "SomeTenant", tenant_id: 1)
      other_tenant_tag = described_class.new(name: "Shared Tag", tenant_type: "SomeTenant", tenant_id: 2)
      expect(other_tenant_tag).to be_valid
    end

    describe "colour format" do
      it "accepts valid hex colours" do
        tag = described_class.new(name: "Coloured", colour: "#ff0000")
        expect(tag).to be_valid
      end

      it "accepts uppercase hex colours" do
        tag = described_class.new(name: "Coloured", colour: "#FF0000")
        expect(tag).to be_valid
      end

      it "rejects invalid hex colours" do
        tag = described_class.new(name: "Bad Colour", colour: "red")
        expect(tag).not_to be_valid
        expect(tag.errors[:colour]).to include("must be a hex colour (e.g. #ff0000)")
      end

      it "rejects short hex colours" do
        tag = described_class.new(name: "Short Hex", colour: "#fff")
        expect(tag).not_to be_valid
      end

      it "allows blank colour" do
        tag = described_class.new(name: "No Colour", colour: "")
        expect(tag).to be_valid
      end

      it "allows nil colour" do
        tag = described_class.new(name: "Nil Colour", colour: nil)
        expect(tag).to be_valid
      end
    end
  end

  describe "#normalize_name" do
    it "strips leading whitespace from name" do
      tag = described_class.create!(name: "  Spacey Tag")
      expect(tag.name).to eq("Spacey Tag")
    end

    it "strips trailing whitespace from name" do
      tag = described_class.create!(name: "Spacey Tag  ")
      expect(tag.name).to eq("Spacey Tag")
    end

    it "strips both leading and trailing whitespace" do
      tag = described_class.create!(name: "  Spacey Tag  ")
      expect(tag.name).to eq("Spacey Tag")
    end

    it "handles nil name gracefully" do
      tag = described_class.new(name: nil)
      tag.valid?
      expect(tag.name).to be_nil
    end
  end

  describe "#display_colour" do
    it "returns the colour when set" do
      tag = described_class.new(name: "Coloured", colour: "#ff0000")
      expect(tag.display_colour).to eq("#ff0000")
    end

    it "returns the default grey when colour is nil" do
      tag = described_class.new(name: "No Colour", colour: nil)
      expect(tag.display_colour).to eq("#6b7280")
    end

    it "returns the default grey when colour is blank" do
      tag = described_class.new(name: "Blank Colour", colour: "")
      expect(tag.display_colour).to eq("#6b7280")
    end
  end

  describe "scopes" do
    describe ".for_tenant" do
      let!(:global_tag) { described_class.create!(name: "Global Tag", tenant_type: nil, tenant_id: nil) }
      let!(:tenant_tag) { described_class.create!(name: "Tenant Tag", tenant_type: "SomeTenant", tenant_id: 1) }

      it "returns tags for a specific tenant" do
        tenant = double("Tenant")
        allow(tenant).to receive(:class).and_return(double(base_class: double(name: "SomeTenant")))
        allow(tenant).to receive(:id).and_return(1)

        result = described_class.where(tenant_type: "SomeTenant", tenant_id: 1)
        expect(result).to include(tenant_tag)
        expect(result).not_to include(global_tag)
      end

      it "returns global tags when tenant is nil" do
        result = described_class.for_tenant(nil)
        expect(result).to include(global_tag)
        expect(result).not_to include(tenant_tag)
      end
    end

    describe ".ordered" do
      let!(:tag_b) { described_class.create!(name: "Bravo") }
      let!(:tag_a) { described_class.create!(name: "Alpha") }
      let!(:tag_c) { described_class.create!(name: "Charlie") }

      it "returns tags ordered by name" do
        expect(described_class.ordered).to eq([tag_a, tag_b, tag_c])
      end
    end

    describe ".search_by_name" do
      let!(:ruby_tag) { described_class.create!(name: "Ruby") }
      let!(:rails_tag) { described_class.create!(name: "Rails") }
      let!(:python_tag) { described_class.create!(name: "Python") }

      it "finds tags matching the query" do
        expect(described_class.search_by_name("ruby")).to include(ruby_tag)
      end

      it "is case-insensitive" do
        expect(described_class.search_by_name("RUBY")).to include(ruby_tag)
      end

      it "matches partial names" do
        expect(described_class.search_by_name("ub")).to include(ruby_tag)
      end

      it "does not return non-matching tags" do
        expect(described_class.search_by_name("ruby")).not_to include(python_tag)
      end

      it "handles SQL special characters safely" do
        special_tag = described_class.create!(name: "100% Done")
        expect(described_class.search_by_name("100%")).to include(special_tag)
      end
    end
  end
end
