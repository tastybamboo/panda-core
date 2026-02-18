# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::NavigationRegistry do
  before do
    described_class.reset!
    Panda::Core.reset_config!
  end

  after do
    described_class.reset!
    Panda::Core.reset_config!
  end

  let(:user) { double("User") }

  # Helper: filter to top-level navigation (excludes bottom sections like "My Account")
  def top_items(result)
    result.select { |i| i[:position] == :top }
  end

  describe ".build" do
    it "returns base lambda items when no extra sections or items are registered" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"}]
      }

      result = top_items(described_class.build(user))
      expect(result.length).to eq(1)
      expect(result.first).to include(label: "Dashboard", path: "/admin", icon: "fa-solid fa-house")
    end

    it "returns no top items when no lambda is configured" do
      Panda::Core.config.admin_navigation_items = nil
      result = top_items(described_class.build(user))
      expect(result).to eq([])
    end

    it "sets position: :top on all base lambda items" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"}]
      }

      result = described_class.build(user)
      dashboard = result.find { |i| i[:label] == "Dashboard" }
      expect(dashboard[:position]).to eq(:top)
    end
  end

  describe ".section" do
    it "adds a new section appended to the end by default" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"}]
      }

      described_class.section("Tools", icon: "fa-solid fa-wrench")

      result = top_items(described_class.build(user))
      expect(result.length).to eq(2)
      expect(result.last[:label]).to eq("Tools")
      expect(result.last[:icon]).to eq("fa-solid fa-wrench")
    end

    it "inserts a section after a named section" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [
          {label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"},
          {label: "Settings", icon: "fa-solid fa-gear", children: []}
        ]
      }

      described_class.section("Website", icon: "fa-solid fa-globe", after: "Dashboard")

      result = top_items(described_class.build(user))
      expect(result.map { |i| i[:label] }).to eq(["Dashboard", "Website", "Settings"])
    end

    it "inserts a section before a named section" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [
          {label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"},
          {label: "Settings", icon: "fa-solid fa-gear", children: []}
        ]
      }

      described_class.section("Website", icon: "fa-solid fa-globe", before: "Settings")

      result = top_items(described_class.build(user))
      expect(result.map { |i| i[:label] }).to eq(["Dashboard", "Website", "Settings"])
    end

    it "appends to end when after: target is not found" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"}]
      }

      described_class.section("Tools", icon: "fa-solid fa-wrench", after: "NonExistent")

      result = top_items(described_class.build(user))
      expect(result.last[:label]).to eq("Tools")
    end

    it "appends to end when before: target is not found" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"}]
      }

      described_class.section("Tools", icon: "fa-solid fa-wrench", before: "NonExistent")

      result = top_items(described_class.build(user))
      expect(result.last[:label]).to eq("Tools")
    end

    it "adds a section with items via a block" do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }
      Panda::Core.config.admin_path = "/admin"

      described_class.section("Members", icon: "fa-solid fa-users") do |s|
        s.item "Onboarding", path: "members/onboarding"
        s.item "Directory", path: "members/directory"
      end

      result = top_items(described_class.build(user))
      expect(result.length).to eq(1)
      expect(result.first[:children].length).to eq(2)
      expect(result.first[:children].first[:label]).to eq("Onboarding")
      expect(result.first[:children].first[:path]).to eq("/admin/members/onboarding")
    end

    it "skips a section if one with the same label already exists in base" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Settings", icon: "fa-solid fa-gear", children: []}]
      }

      described_class.section("Settings", icon: "fa-solid fa-cog")

      result = top_items(described_class.build(user))
      expect(result.length).to eq(1)
      # Should keep original icon, not the registered one
      expect(result.first[:icon]).to eq("fa-solid fa-gear")
    end
  end

  describe ".item" do
    it "adds an item to an existing section" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Settings", icon: "fa-solid fa-gear", children: []}]
      }
      Panda::Core.config.admin_path = "/admin"

      described_class.item("Feature Flags", section: "Settings", path: "feature_flags")

      result = described_class.build(user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].length).to eq(1)
      expect(settings[:children].first[:label]).to eq("Feature Flags")
      expect(settings[:children].first[:path]).to eq("/admin/feature_flags")
    end

    it "creates children array if section has none" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Settings", icon: "fa-solid fa-gear"}]
      }
      Panda::Core.config.admin_path = "/admin"

      described_class.item("Feature Flags", section: "Settings", path: "feature_flags")

      result = described_class.build(user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children]).to be_an(Array)
      expect(settings[:children].first[:label]).to eq("Feature Flags")
    end

    it "silently skips when the target section does not exist" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"}]
      }

      described_class.item("Orphan", section: "NonExistent", path: "orphan")

      result = top_items(described_class.build(user))
      expect(result.length).to eq(1)
      expect(result.first[:label]).to eq("Dashboard")
    end
  end

  describe "path resolution" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Settings", icon: "fa-solid fa-gear", children: []}]
      }
    end

    it "auto-prefixes path: with admin_path" do
      Panda::Core.config.admin_path = "/admin"
      described_class.item("Flags", section: "Settings", path: "feature_flags")

      result = described_class.build(user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].first[:path]).to eq("/admin/feature_flags")
    end

    it "uses url: as-is without prefixing" do
      described_class.item("Docs", section: "Settings", url: "https://docs.example.com")

      result = described_class.build(user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].first[:path]).to eq("https://docs.example.com")
    end

    it "respects custom admin_path" do
      Panda::Core.config.admin_path = "/backend"
      described_class.item("Flags", section: "Settings", path: "feature_flags")

      result = described_class.build(user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].first[:path]).to eq("/backend/feature_flags")
    end
  end

  describe "target attribute" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Help", icon: "fa-solid fa-question", children: []}]
      }
    end

    it "includes target in item hash when present" do
      described_class.item("Docs", section: "Help", url: "https://docs.example.com", target: "_blank")

      result = described_class.build(user)
      help = result.find { |i| i[:label] == "Help" }
      expect(help[:children].first[:target]).to eq("_blank")
    end

    it "omits target from item hash when nil" do
      described_class.item("FAQ", section: "Help", path: "faq")

      result = described_class.build(user)
      help = result.find { |i| i[:label] == "Help" }
      expect(help[:children].first).not_to have_key(:target)
    end

    it "includes target in section block items" do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }

      described_class.section("External", icon: "fa-solid fa-link") do |s|
        s.item "Docs", url: "https://docs.example.com", target: "_blank"
      end

      result = described_class.build(user)
      external = result.find { |i| i[:label] == "External" }
      expect(external[:children].first[:target]).to eq("_blank")
    end
  end

  describe "configuration convenience methods" do
    it "delegates insert_admin_menu_section to NavigationRegistry.section" do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }
      Panda::Core.config.admin_path = "/admin"

      Panda::Core.configure do |config|
        config.insert_admin_menu_section "Members", icon: "fa-solid fa-users" do |s|
          s.item "Onboarding", path: "members/onboarding"
        end
      end

      result = top_items(described_class.build(user))
      expect(result.first[:label]).to eq("Members")
      expect(result.first[:children].first[:path]).to eq("/admin/members/onboarding")
    end

    it "delegates insert_admin_menu_item to NavigationRegistry.item" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Settings", icon: "fa-solid fa-gear", children: []}]
      }
      Panda::Core.config.admin_path = "/admin"

      Panda::Core.configure do |config|
        config.insert_admin_menu_item "Feature Flags", section: "Settings", path: "feature_flags"
      end

      result = described_class.build(user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].first[:label]).to eq("Feature Flags")
    end
  end

  describe ".reset!" do
    it "clears all registered sections, items, and filters" do
      described_class.section("Tools", icon: "fa-solid fa-wrench")
      described_class.item("Flags", section: "Settings", path: "flags")
      described_class.filter("Flags", visible: ->(user) { false })

      described_class.reset!

      expect(described_class.sections).to be_empty
      expect(described_class.items).to be_empty
      expect(described_class.filters).to be_empty
    end
  end
end
