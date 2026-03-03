# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::HasMetadata, type: :model do
  # Tested through User, which includes HasMetadata and declares:
  #   metadata_field :internal, type: :boolean, filterable: true,
  #     default_scope: :external, ...

  let(:user) { Panda::Core::User.create!(email: "meta@example.com", name: "Meta User") }

  # -- Generic metadata accessors --

  describe "#metadata_value" do
    it "returns nil for an unset key" do
      expect(user.metadata_value("foo")).to be_nil
    end

    it "returns the value when set" do
      user.set_metadata("foo", "bar")
      expect(user.reload.metadata_value("foo")).to eq("bar")
    end
  end

  describe "#set_metadata" do
    it "persists the value" do
      user.set_metadata("colour", "blue")
      expect(user.reload.metadata_value("colour")).to eq("blue")
    end

    it "preserves existing keys" do
      user.set_metadata("a", 1)
      user.set_metadata("b", 2)
      expect(user.reload.metadata_value("a")).to eq(1)
      expect(user.reload.metadata_value("b")).to eq(2)
    end
  end

  describe "#set_metadata_attribute" do
    it "sets the value in memory without saving" do
      user.set_metadata_attribute("draft", true)
      expect(user.metadata_value("draft")).to eq(true)
      expect(user.reload.metadata_value("draft")).to be_nil
    end
  end

  describe "#remove_metadata" do
    it "removes the key and saves" do
      user.set_metadata("temp", "yes")
      user.remove_metadata("temp")
      expect(user.reload.metadata_value("temp")).to be_nil
    end
  end

  # -- Boolean field: internal --

  describe "#internal? / #mark_as_internal! / #mark_as_external!" do
    it "defaults to false" do
      expect(user.internal?).to be false
    end

    it "marks as internal and persists" do
      user.mark_as_internal!
      expect(user.reload.internal?).to be true
    end

    it "marks as external (removes key) and persists" do
      user.mark_as_internal!
      user.mark_as_external!
      expect(user.reload.internal?).to be false
      expect(user.reload.metadata).not_to have_key("internal")
    end
  end

  describe "#internal= (virtual attribute setter)" do
    it "sets true from checkbox '1'" do
      user.internal = "1"
      expect(user.internal?).to be true
    end

    it "removes key from checkbox '0'" do
      user.mark_as_internal!
      user.internal = "0"
      expect(user.internal?).to be false
      expect(user.metadata).not_to have_key("internal")
    end
  end

  # -- Scopes --

  describe ".internal scope" do
    it "returns only internal users" do
      internal_user = Panda::Core::User.create!(email: "staff@example.com", name: "Staff")
      internal_user.mark_as_internal!

      expect(Panda::Core::User.internal).to include(internal_user)
      expect(Panda::Core::User.internal).not_to include(user)
    end
  end

  describe ".external scope" do
    it "returns only non-internal users" do
      internal_user = Panda::Core::User.create!(email: "staff@example.com", name: "Staff")
      internal_user.mark_as_internal!

      expect(Panda::Core::User.external).to include(user)
      expect(Panda::Core::User.external).not_to include(internal_user)
    end
  end

  describe ".with_metadata scope" do
    it "filters by arbitrary key/value" do
      user.set_metadata("tier", "gold")
      other = Panda::Core::User.create!(email: "other@example.com", name: "Other")

      expect(Panda::Core::User.with_metadata("tier", "gold")).to include(user)
      expect(Panda::Core::User.with_metadata("tier", "gold")).not_to include(other)
    end
  end

  # -- DSL class methods --

  describe ".filterable_metadata_fields" do
    it "includes the internal field" do
      fields = Panda::Core::User.filterable_metadata_fields
      expect(fields).to have_key("internal")
      expect(fields["internal"][:label]).to eq("Visibility")
    end
  end

  describe ".apply_metadata_filters" do
    let!(:internal_user) do
      Panda::Core::User.create!(email: "staff@example.com", name: "Staff").tap(&:mark_as_internal!)
    end

    it "applies the internal scope when param matches" do
      result = Panda::Core::User.apply_metadata_filters(Panda::Core::User.all, {internal: "internal"})
      expect(result).to include(internal_user)
      expect(result).not_to include(user)
    end

    it "applies the external scope when param matches" do
      result = Panda::Core::User.apply_metadata_filters(Panda::Core::User.all, {internal: "external"})
      expect(result).to include(user)
      expect(result).not_to include(internal_user)
    end

    it "ignores unknown param values" do
      result = Panda::Core::User.apply_metadata_filters(Panda::Core::User.all, {internal: "hacked_scope"})
      expect(result).to include(user, internal_user)
    end

    it "returns unfiltered scope when param is blank" do
      result = Panda::Core::User.apply_metadata_filters(Panda::Core::User.all, {internal: ""})
      expect(result).to include(user, internal_user)
    end
  end

  describe ".metadata_filter_active?" do
    it "returns true when a filterable metadata param is present" do
      expect(Panda::Core::User.metadata_filter_active?({internal: "internal"})).to be true
    end

    it "returns false when no metadata params are present" do
      expect(Panda::Core::User.metadata_filter_active?({status: "enabled"})).to be false
    end
  end
end
