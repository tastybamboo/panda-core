# frozen_string_literal: true

require "system_helper"

RSpec.describe "Core admin pages smoke tests", type: :system do
  # These tests ensure all core admin pages can load without 500 errors
  # They're intentionally simple - just verify the page loads and doesn't crash

  let!(:admin_user) { create_admin_user }

  before do
    login_as_admin
  end

  describe "Core Dashboard" do
    it "loads without errors" do
      visit "/admin"
      expect(page).to have_css("body")
      expect(page.status_code).to eq(200)
    end
  end

  describe "My Profile" do
    it "loads profile show page without errors" do
      visit "/admin/my_profile"
      expect(page).to have_css("body")
      expect(page.status_code).to eq(200)
    end

    it "loads profile edit page without errors" do
      visit "/admin/my_profile/edit"
      expect(page).to have_css("body")
      expect(page.status_code).to eq(200)
    end

    it "loads login & security page without errors" do
      visit "/admin/my_profile/logins"
      expect(page).to have_content("Login & Security")
      expect(page.status_code).to eq(200)
    end
  end

  describe "Settings" do
    it "loads settings page without errors" do
      visit "/admin/settings"
      expect(page).to have_css("body")
      expect(page.status_code).to eq(200)
    end
  end

  describe "Users management" do
    context "with a regular user" do
      let!(:regular_user) { create_user }

      it "loads users index without errors" do
        visit "/admin/users"
        expect(page).to have_css("body")
        expect(page.status_code).to eq(200)
      end

      it "loads user show page without errors" do
        visit "/admin/users/#{regular_user.id}"
        expect(page).to have_css("body")
        expect(page.status_code).to eq(200)
      end

      it "loads user edit page without errors" do
        visit "/admin/users/#{regular_user.id}/edit"
        expect(page).to have_css("body")
        expect(page.status_code).to eq(200)
      end
    end
  end

  describe "File Categories" do
    it "loads file categories index without errors" do
      visit "/admin/file_categories"
      expect(page).to have_css("body")
      expect(page.status_code).to eq(200)
    end

    it "loads new file category form without errors" do
      visit "/admin/file_categories/new"
      expect(page).to have_css("body")
      expect(page.status_code).to eq(200)
    end

    context "with a test category", skip: "requires factory_bot setup" do
      let!(:category) { Panda::Core::FileCategory.create!(name: "Test Category") }

      it "loads file category edit without errors" do
        visit "/admin/file_categories/#{category.id}/edit"
        expect(page).to have_css("body")
        expect(page.status_code).to eq(200)
      end
    end
  end

  describe "Error handling" do
    it "returns 404 for non-existent routes instead of 500" do
      visit "/admin/nonexistent_route"
      # Should get a 404, not a 500
      expect(page.status_code).to be_in([404, 200])
      # If it's 200, it should be showing an error page
      if page.status_code == 200
        expect(page).to have_content(/not found|404/i)
      end
    end
  end
end
