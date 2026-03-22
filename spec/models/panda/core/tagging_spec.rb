# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Tagging, type: :model do
  describe "associations" do
    it { should belong_to(:tag).class_name("Panda::Core::Tag") }
    it { should belong_to(:taggable) }
  end

  describe "validations" do
    it "validates uniqueness of tag_id scoped to taggable" do
      tag = Panda::Core::Tag.create!(name: "Test Tag")
      user = Panda::Core::User.create!(name: "Test User", email: "tagging-test@example.com")

      described_class.create!(tag: tag, taggable: user)
      duplicate = described_class.new(tag: tag, taggable: user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tag_id]).to include("has already been taken")
    end

    it "allows the same tag on different taggables" do
      tag = Panda::Core::Tag.create!(name: "Shared Tag")
      user1 = Panda::Core::User.create!(name: "User One", email: "tagging-user1@example.com")
      user2 = Panda::Core::User.create!(name: "User Two", email: "tagging-user2@example.com")

      described_class.create!(tag: tag, taggable: user1)
      second_tagging = described_class.new(tag: tag, taggable: user2)

      expect(second_tagging).to be_valid
    end

    it "allows different tags on the same taggable" do
      tag1 = Panda::Core::Tag.create!(name: "Tag One")
      tag2 = Panda::Core::Tag.create!(name: "Tag Two")
      user = Panda::Core::User.create!(name: "Tagged User", email: "tagging-multi@example.com")

      described_class.create!(tag: tag1, taggable: user)
      second_tagging = described_class.new(tag: tag2, taggable: user)

      expect(second_tagging).to be_valid
    end
  end

  describe "counter_cache" do
    it "increments taggings_count on the tag" do
      tag = Panda::Core::Tag.create!(name: "Counted Tag")
      user = Panda::Core::User.create!(name: "Counter User", email: "tagging-counter@example.com")

      expect {
        described_class.create!(tag: tag, taggable: user)
      }.to change { tag.reload.taggings_count }.from(0).to(1)
    end

    it "decrements taggings_count when tagging is destroyed" do
      tag = Panda::Core::Tag.create!(name: "Decrement Tag")
      user = Panda::Core::User.create!(name: "Decrement User", email: "tagging-decrement@example.com")
      tagging = described_class.create!(tag: tag, taggable: user)

      expect {
        tagging.destroy
      }.to change { tag.reload.taggings_count }.from(1).to(0)
    end
  end
end
