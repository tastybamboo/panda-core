# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::NavigationRegistry, "visibility and filtering" do
  before do
    described_class.reset!
    Panda::Core.reset_config!
    Panda::Core.config.admin_path = "/admin"
  end

  after do
    described_class.reset!
    Panda::Core.reset_config!
  end

  let(:admin_user) { double("AdminUser", admin?: true, has_permission?: true) }
  let(:regular_user) { double("RegularUser", admin?: false, has_permission?: false) }

  describe "section visible:" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }
    end

    it "shows section when visible: returns true" do
      described_class.section("Settings", icon: "fa-solid fa-gear",
        visible: ->(user) { user.admin? })

      result = described_class.build(admin_user)
      expect(result.map { |i| i[:label] }).to include("Settings")
    end

    it "hides section when visible: returns false" do
      described_class.section("Settings", icon: "fa-solid fa-gear",
        visible: ->(user) { user.admin? })

      result = described_class.build(regular_user)
      expect(result.map { |i| i[:label] }).not_to include("Settings")
    end

    it "always shows section when visible: is nil" do
      described_class.section("Tools", icon: "fa-solid fa-wrench")

      result = described_class.build(regular_user)
      expect(result.map { |i| i[:label] }).to include("Tools")
    end
  end

  describe "item visible:" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Settings", icon: "fa-solid fa-gear", children: []}]
      }
    end

    it "shows item when visible: returns true" do
      described_class.item("Roles", section: "Settings", path: "roles",
        visible: ->(user) { user.admin? })

      result = described_class.build(admin_user)
      expect(result.first[:children].map { |c| c[:label] }).to include("Roles")
    end

    it "hides item when visible: returns false" do
      described_class.item("Roles", section: "Settings", path: "roles",
        visible: ->(user) { user.admin? })

      result = described_class.build(regular_user)
      expect(result.first[:children].map { |c| c[:label] }).not_to include("Roles")
    end

    it "always shows item when visible: is nil" do
      described_class.item("Feature Flags", section: "Settings", path: "feature_flags")

      result = described_class.build(regular_user)
      expect(result.first[:children].map { |c| c[:label] }).to include("Feature Flags")
    end
  end

  describe "section block item visible:" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }
    end

    it "hides individual items within a section block" do
      described_class.section("Settings", icon: "fa-solid fa-gear") do |s|
        s.item "Feature Flags", path: "feature_flags"
        s.item "Roles", path: "roles", visible: ->(user) { user.admin? }
      end

      admin_result = described_class.build(admin_user)
      settings = admin_result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].length).to eq(2)

      # Reset and re-register for clean build
      described_class.reset!
      Panda::Core.reset_config!
      described_class.section("Settings", icon: "fa-solid fa-gear") do |s|
        s.item "Feature Flags", path: "feature_flags"
        s.item "Roles", path: "roles", visible: ->(user) { user.admin? }
      end

      regular_result = described_class.build(regular_user)
      settings = regular_result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].length).to eq(1)
      expect(settings[:children].first[:label]).to eq("Feature Flags")
    end
  end

  describe ".filter" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [
          {label: "Dashboard", path: "/admin", icon: "fa-solid fa-house"},
          {
            label: "Settings",
            icon: "fa-solid fa-gear",
            children: [
              {label: "Feature Flags", path: "/admin/feature_flags"},
              {label: "Roles", path: "/admin/roles"}
            ]
          }
        ]
      }
    end

    it "removes a child item when filter visible: returns false" do
      described_class.filter("Roles", visible: ->(user) { user.admin? })

      result = described_class.build(regular_user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].map { |c| c[:label] }).to eq(["Feature Flags"])
    end

    it "keeps a child item when filter visible: returns true" do
      described_class.filter("Roles", visible: ->(user) { user.admin? })

      result = described_class.build(admin_user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].map { |c| c[:label] }).to include("Roles")
    end

    it "can filter a top-level section by label" do
      described_class.filter("Settings", visible: ->(user) { user.admin? })

      result = described_class.build(regular_user)
      top = result.select { |i| i[:position] == :top }
      expect(top.map { |i| i[:label] }).to eq(["Dashboard"])
    end

    it "applies multiple filters" do
      described_class.filter("Roles", visible: ->(user) { user.admin? })
      described_class.filter("Feature Flags", visible: ->(user) { user.admin? })

      result = described_class.build(regular_user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children]).to be_empty
    end

    it "is cleared by reset!" do
      described_class.filter("Roles", visible: ->(user) { false })
      described_class.reset!

      result = described_class.build(admin_user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children].map { |c| c[:label] }).to include("Roles")
    end
  end

  describe "item before:/after: positioning" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{
          label: "Settings",
          icon: "fa-solid fa-gear",
          children: [
            {label: "Feature Flags", path: "/admin/feature_flags"},
            {label: "Roles", path: "/admin/roles"}
          ]
        }]
      }
    end

    it "inserts at beginning with before: :all" do
      described_class.item("General", section: "Settings", path: "general", before: :all)

      result = described_class.build(admin_user)
      labels = result.first[:children].map { |c| c[:label] }
      expect(labels).to eq(["General", "Feature Flags", "Roles"])
    end

    it "inserts before a named item" do
      described_class.item("General", section: "Settings", path: "general", before: "Roles")

      result = described_class.build(admin_user)
      labels = result.first[:children].map { |c| c[:label] }
      expect(labels).to eq(["Feature Flags", "General", "Roles"])
    end

    it "inserts after a named item" do
      described_class.item("General", section: "Settings", path: "general", after: "Feature Flags")

      result = described_class.build(admin_user)
      labels = result.first[:children].map { |c| c[:label] }
      expect(labels).to eq(["Feature Flags", "General", "Roles"])
    end

    it "appends to end with after: :all" do
      described_class.item("General", section: "Settings", path: "general", after: :all)

      result = described_class.build(admin_user)
      labels = result.first[:children].map { |c| c[:label] }
      expect(labels).to eq(["Feature Flags", "Roles", "General"])
    end

    it "appends to end when before: target not found" do
      described_class.item("General", section: "Settings", path: "general", before: "NonExistent")

      result = described_class.build(admin_user)
      labels = result.first[:children].map { |c| c[:label] }
      expect(labels.last).to eq("General")
    end

    it "appends to end when after: target not found" do
      described_class.item("General", section: "Settings", path: "general", after: "NonExistent")

      result = described_class.build(admin_user)
      labels = result.first[:children].map { |c| c[:label] }
      expect(labels.last).to eq("General")
    end
  end

  describe "position:" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }
    end

    it "defaults to :top position" do
      described_class.section("Tools", icon: "fa-solid fa-wrench")

      result = described_class.build(admin_user)
      tools = result.find { |i| i[:label] == "Tools" }
      expect(tools[:position]).to eq(:top)
    end

    it "supports :bottom position" do
      described_class.section("My Account", position: :bottom) do |s|
        s.item "Profile", path: "my_profile/edit"
      end

      result = described_class.build(admin_user)
      expect(result.first[:position]).to eq(:bottom)
    end

    it "allows mixed top and bottom sections" do
      described_class.section("Tools", icon: "fa-solid fa-wrench")
      described_class.section("My Account", position: :bottom) do |s|
        s.item "Profile", path: "my_profile/edit"
      end

      result = described_class.build(admin_user)
      top = result.select { |i| i[:position] == :top }
      bottom = result.select { |i| i[:position] == :bottom }
      expect(top.length).to eq(1)
      expect(bottom.length).to eq(1)
    end
  end

  describe "method: and button_options:" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }
    end

    it "includes method and button_options in resolved items" do
      described_class.section("Actions", position: :bottom) do |s|
        s.item "Logout", path: "logout", method: :delete,
          button_options: {id: "logout-link", data: {turbo: false}}
      end

      result = described_class.build(admin_user)
      actions = result.find { |i| i[:label] == "Actions" }
      logout = actions[:children].first
      expect(logout[:method]).to eq(:delete)
      expect(logout[:button_options]).to eq({id: "logout-link", data: {turbo: false}})
    end

    it "omits method and button_options when not set" do
      described_class.section("Actions", position: :bottom) do |s|
        s.item "Profile", path: "my_profile/edit"
      end

      result = described_class.build(admin_user)
      actions = result.find { |i| i[:label] == "Actions" }
      profile = actions[:children].first
      expect(profile).not_to have_key(:method)
      expect(profile).not_to have_key(:button_options)
    end
  end

  describe "path_helper:" do
    before do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }
    end

    it "resolves path_helper via helpers when provided" do
      panda_core_routes = double("PandaCoreRoutes", admin_logout_path: "/admin")
      mock_helpers = double("Helpers", panda_core: panda_core_routes)

      described_class.section("Test Menu", position: :bottom) do |s|
        s.item "Sign Out", path_helper: :admin_logout_path, method: :delete
      end

      result = described_class.build(admin_user, helpers: mock_helpers)
      test_menu = result.find { |i| i[:label] == "Test Menu" }
      sign_out = test_menu[:children].first
      expect(sign_out[:path]).to eq("/admin")
    end

    it "keeps path_helper when helpers not provided" do
      described_class.section("Test Menu", position: :bottom) do |s|
        s.item "Sign Out", path_helper: :admin_logout_path, method: :delete
      end

      result = described_class.build(admin_user)
      test_menu = result.find { |i| i[:label] == "Test Menu" }
      sign_out = test_menu[:children].first
      expect(sign_out[:path_helper]).to eq(:admin_logout_path)
      expect(sign_out).not_to have_key(:path)
    end
  end

  describe "configuration convenience methods" do
    it "delegates filter_admin_menu to NavigationRegistry.filter" do
      Panda::Core.config.admin_navigation_items = ->(user) {
        [{label: "Settings", icon: "fa-solid fa-gear", children: [
          {label: "Roles", path: "/admin/roles"}
        ]}]
      }

      Panda::Core.configure do |config|
        config.filter_admin_menu "Roles", visible: ->(user) { user.admin? }
      end

      result = described_class.build(regular_user)
      settings = result.find { |i| i[:label] == "Settings" }
      expect(settings[:children]).to be_empty
    end

    it "delegates insert_admin_user_menu_item to NavigationRegistry" do
      Panda::Core.configure do |config|
        config.insert_admin_user_menu_item "API Tokens", path: "my_profile/api_tokens"
      end

      result = described_class.build(admin_user)
      my_account = result.find { |i| i[:label] == "My Account" }
      expect(my_account).to be_present
      labels = my_account[:children].map { |c| c[:label] }
      expect(labels).to include("API Tokens")
      # Should be before Logout by default
      expect(labels.index("API Tokens")).to be < labels.index("Logout")
    end

    it "delegates insert_admin_menu_section with visible: and position:" do
      Panda::Core.config.admin_navigation_items = ->(user) { [] }

      Panda::Core.configure do |config|
        config.insert_admin_menu_section "Notifications",
          position: :bottom,
          visible: ->(user) { user.admin? } do |s|
          s.item "All", path: "notifications"
        end
      end

      admin_result = described_class.build(admin_user)
      expect(admin_result.map { |i| i[:label] }).to include("Notifications")

      # Re-register for clean build
      described_class.reset!
      Panda::Core.configure do |config|
        config.insert_admin_menu_section "Notifications",
          position: :bottom,
          visible: ->(user) { user.admin? } do |s|
          s.item "All", path: "notifications"
        end
      end

      regular_result = described_class.build(regular_user)
      expect(regular_result.map { |i| i[:label] }).not_to include("Notifications")
    end
  end

  describe "default user menu" do
    it "registers a My Account bottom section with default items" do
      result = described_class.build(admin_user)
      my_account = result.find { |i| i[:label] == "My Account" }

      expect(my_account).to be_present
      expect(my_account[:position]).to eq(:bottom)

      labels = my_account[:children].map { |c| c[:label] }
      expect(labels).to eq(["My Profile", "Login & Security", "Logout"])
    end

    it "resolves My Profile and Login & Security paths" do
      result = described_class.build(admin_user)
      my_account = result.find { |i| i[:label] == "My Account" }

      profile = my_account[:children].find { |c| c[:label] == "My Profile" }
      expect(profile[:path]).to eq("/admin/my_profile/edit")

      logins = my_account[:children].find { |c| c[:label] == "Login & Security" }
      expect(logins[:path]).to eq("/admin/my_profile/logins")
    end

    it "sets Logout with method: :delete and button_options" do
      result = described_class.build(admin_user)
      my_account = result.find { |i| i[:label] == "My Account" }

      logout = my_account[:children].find { |c| c[:label] == "Logout" }
      expect(logout[:method]).to eq(:delete)
      expect(logout[:button_options]).to eq({id: "logout-link", data: {turbo: false}})
    end
  end

  describe "legacy admin_user_menu_items backward compatibility" do
    it "migrates legacy items into the My Account section before Logout" do
      Panda::Core.config.admin_user_menu_items = [
        {label: "API Tokens", path: "/admin/my_profile/api_tokens"}
      ]

      result = described_class.build(admin_user)
      my_account = result.find { |i| i[:label] == "My Account" }
      labels = my_account[:children].map { |c| c[:label] }

      expect(labels).to include("API Tokens")
      expect(labels.index("API Tokens")).to be < labels.index("Logout")
    end

    it "skips legacy items with blank paths" do
      Panda::Core.config.admin_user_menu_items = [
        {label: "No Path", path: nil}
      ]

      result = described_class.build(admin_user)
      my_account = result.find { |i| i[:label] == "My Account" }
      labels = my_account[:children].map { |c| c[:label] }
      expect(labels).not_to include("No Path")
    end
  end
end
