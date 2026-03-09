# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::PermissionRegistry do
  before { described_class.reset! }
  after { described_class.reset! }

  describe ".register" do
    it "registers permissions for a controller" do
      described_class.register("Admin::PagesController", index: :edit_content, destroy: :delete_content)

      expect(described_class.permissions_for("Admin::PagesController")).to eq(
        index: :edit_content,
        destroy: :delete_content
      )
    end

    it "merges permissions from multiple registrations" do
      described_class.register("Admin::PagesController", index: :edit_content)
      described_class.register("Admin::PagesController", destroy: :delete_content)

      expect(described_class.permissions_for("Admin::PagesController")).to eq(
        index: :edit_content,
        destroy: :delete_content
      )
    end

    it "overwrites duplicate action keys from later registrations" do
      described_class.register("Admin::PagesController", index: :edit_content)
      described_class.register("Admin::PagesController", index: :manage_settings)

      expect(described_class.permission_for("Admin::PagesController", :index)).to eq(:manage_settings)
    end
  end

  describe ".permission_for" do
    before do
      described_class.register("Admin::PagesController", index: :edit_content, destroy: :delete_content)
    end

    it "returns the permission for a mapped action" do
      expect(described_class.permission_for("Admin::PagesController", :index)).to eq(:edit_content)
    end

    it "returns nil for an unmapped action" do
      expect(described_class.permission_for("Admin::PagesController", :show)).to be_nil
    end

    it "returns nil for an unmapped controller" do
      expect(described_class.permission_for("Admin::DashboardController", :index)).to be_nil
    end
  end

  describe ".all" do
    it "returns a copy of the registry" do
      described_class.register("Admin::PagesController", index: :edit_content)

      all = described_class.all
      expect(all).to eq("Admin::PagesController" => {index: :edit_content})

      # Modifying the copy doesn't affect the registry
      all["Admin::PagesController"][:index] = :modified
      expect(described_class.permission_for("Admin::PagesController", :index)).to eq(:edit_content)
    end
  end

  describe ".reset!" do
    it "clears all registrations" do
      described_class.register("Admin::PagesController", index: :edit_content)
      described_class.reset!

      expect(described_class.permissions_for("Admin::PagesController")).to be_nil
    end
  end
end
