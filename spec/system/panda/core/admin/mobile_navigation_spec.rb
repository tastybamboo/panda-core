# frozen_string_literal: true

require "system_helper"

RSpec.describe "Mobile admin navigation", type: :system do
  let(:admin_user) { create_admin_user }
  let(:desktop_size) { [1280, 720] }
  let(:tablet_size) { [768, 1024] }
  let(:mobile_size) { [375, 667] }

  before do
    login_with_google(admin_user)
    expect(page).to have_current_path(%r{/admin})
  end

  after do
    # Cuprite shares the browser process, so resize persists across tests.
    # Restore to desktop size to avoid polluting subsequent specs.
    page.current_window.resize_to(*desktop_size)
  end

  context "at desktop width (1280x720)" do
    before do
      page.current_window.resize_to(*desktop_size)
    end

    it "shows full sidebar navigation" do
      visit "/admin"
      expect(page).to have_css("nav", visible: true)
      expect(page).to have_content("Panda Admin")
    end

    it "does not show the hamburger button" do
      visit "/admin"
      expect(page).not_to have_css("[aria-label='Toggle navigation']", visible: true)
    end
  end

  context "at tablet width (768x1024)" do
    before do
      page.current_window.resize_to(*tablet_size)
    end

    it "shows the hamburger button" do
      visit "/admin"
      expect(page).to have_css("[aria-label='Toggle navigation']", visible: true, wait: 3)
    end

    it "hides nav items by default" do
      visit "/admin"
      # The sidebar is collapsed to max-h-16, hiding overflow nav content
      sidebar = find("[data-mobile-sidebar-target='sidebar']", visible: true)
      expect(sidebar[:class]).to include("max-h-16")
      expect(sidebar[:class]).not_to include("max-h-screen")
    end

    it "expands sidebar when hamburger is clicked" do
      visit "/admin"
      hamburger = find("[aria-label='Toggle navigation']", visible: true, wait: 3)
      hamburger.click

      sidebar = find("[data-mobile-sidebar-target='sidebar']")
      expect(sidebar[:class]).to include("max-h-screen")
      expect(sidebar[:class]).not_to include("max-h-16")

      # Backdrop should be visible (check exact class, not substring — lg:hidden is always present)
      backdrop = find("[data-mobile-sidebar-target='backdrop']")
      expect(backdrop[:class].split).not_to include("hidden")
    end

    it "closes sidebar when backdrop is clicked" do
      visit "/admin"
      hamburger = find("[aria-label='Toggle navigation']", visible: true, wait: 3)
      hamburger.click

      # Verify it's open
      expect(find("[data-mobile-sidebar-target='sidebar']")[:class]).to include("max-h-screen")

      # Click backdrop to close
      find("[data-mobile-sidebar-target='backdrop']").click

      sidebar = find("[data-mobile-sidebar-target='sidebar']")
      expect(sidebar[:class]).to include("max-h-16")
      expect(sidebar[:class]).not_to include("max-h-screen")
    end

    it "closes sidebar when Escape is pressed" do
      visit "/admin"
      hamburger = find("[aria-label='Toggle navigation']", visible: true, wait: 3)
      hamburger.click

      expect(find("[data-mobile-sidebar-target='sidebar']")[:class]).to include("max-h-screen")

      # Press Escape
      page.send_keys(:escape)

      sidebar = find("[data-mobile-sidebar-target='sidebar']")
      expect(sidebar[:class]).to include("max-h-16")
      expect(sidebar[:class]).not_to include("max-h-screen")
    end

    it "toggles aria-expanded on the hamburger button" do
      visit "/admin"
      hamburger = find("[aria-label='Toggle navigation']", visible: true, wait: 3)
      expect(hamburger["aria-expanded"]).to eq("false")

      hamburger.click
      expect(hamburger["aria-expanded"]).to eq("true")

      hamburger.click
      expect(hamburger["aria-expanded"]).to eq("false")
    end
  end

  context "at mobile width (375x667)" do
    before do
      page.current_window.resize_to(*mobile_size)
    end

    it "shows the hamburger button" do
      visit "/admin"
      expect(page).to have_css("[aria-label='Toggle navigation']", visible: true, wait: 3)
    end

    it "shows admin title in mobile header" do
      visit "/admin"
      expect(page).to have_css(".lg\\:hidden span", text: "Panda Admin", visible: true)
    end

    it "toggles sidebar open and closed" do
      visit "/admin"
      hamburger = find("[aria-label='Toggle navigation']", visible: true, wait: 3)

      # Open
      hamburger.click
      expect(find("[data-mobile-sidebar-target='sidebar']")[:class]).to include("max-h-screen")

      # Close
      hamburger.click
      expect(find("[data-mobile-sidebar-target='sidebar']")[:class]).to include("max-h-16")
    end
  end

  context "responsive transition" do
    it "auto-closes sidebar when resized above 1024px" do
      page.current_window.resize_to(*tablet_size)
      visit "/admin"

      # Open the sidebar at tablet width
      hamburger = find("[aria-label='Toggle navigation']", visible: true, wait: 3)
      hamburger.click
      expect(find("[data-mobile-sidebar-target='sidebar']")[:class]).to include("max-h-screen")

      # Resize to desktop width — controller should auto-close
      page.current_window.resize_to(*desktop_size)

      # Wait for the matchMedia listener to fire
      sidebar = find("[data-mobile-sidebar-target='sidebar']")
      expect(sidebar[:class]).to include("max-h-16"), "Expected sidebar to auto-close after resize to desktop width"
    end
  end
end
