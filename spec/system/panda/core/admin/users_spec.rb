# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin Users Management", type: :system do
  let(:admin_user) { create_admin_user }
  let(:regular_user) { create_regular_user }

  before do
    login_with_google(admin_user)
  end

  describe "Users index page" do
    it "shows list of users" do
      # Ensure users exist
      admin_user
      regular_user

      visit "/admin/users"

      expect(page).to have_content("Users")
      expect(page).to have_content(admin_user.name)
      expect(page).to have_content(admin_user.email)
    end

    it "displays admin badge for admin users" do
      admin_user
      regular_user

      visit "/admin/users"

      # Admin user should have admin badge
      expect(page).to have_content("Admin")
      # Regular user should show "User"
      expect(page).to have_content("User")
    end

    it "has edit links for users" do
      admin_user

      visit "/admin/users"

      expect(page).to have_link("Edit", href: "/admin/users/#{admin_user.id}/edit")
    end
  end

  describe "User show page" do
    it "displays user details" do
      visit "/admin/users/#{admin_user.id}"

      expect(page).to have_content(admin_user.name)
      expect(page).to have_content(admin_user.email)
    end
  end

  describe "User edit page" do
    it "shows edit form" do
      visit "/admin/users/#{regular_user.id}/edit"

      expect(page).to have_css("form")
      expect(page).to have_field("user[name]")
      expect(page).to have_field("user[email]")
    end

    it "updates user name" do
      visit "/admin/users/#{regular_user.id}/edit"

      fill_in "user[name]", with: "Updated Name"
      click_button "Save"

      expect(page).to have_content("User has been updated successfully")
      expect(regular_user.reload.name).to eq("Updated Name")
    end

    it "updates user email" do
      visit "/admin/users/#{regular_user.id}/edit"

      fill_in "user[email]", with: "updated@example.com"
      click_button "Save"

      expect(page).to have_content("User has been updated successfully")
      expect(regular_user.reload.email).to eq("updated@example.com")
    end

    it "can grant admin privileges to regular user" do
      visit "/admin/users/#{regular_user.id}/edit"

      check "user[admin]"
      click_button "Save"

      expect(page).to have_content("User has been updated successfully")
      expect(regular_user.reload.admin?).to be true
    end

    it "can revoke admin privileges from another admin" do
      other_admin = Panda::Core::User.create!(
        name: "Other Admin",
        email: "other-admin@example.com",
        is_admin: true
      )

      visit "/admin/users/#{other_admin.id}/edit"

      uncheck "user[admin]"
      click_button "Save"

      expect(page).to have_content("User has been updated successfully")
      expect(other_admin.reload.admin?).to be false
    end
  end

  describe "Breadcrumbs" do
    it "shows breadcrumbs on index page" do
      visit "/admin/users"

      expect(page).to have_content("Users")
    end

    it "shows breadcrumbs on edit page" do
      visit "/admin/users/#{admin_user.id}/edit"

      expect(page).to have_link("Users", href: "/admin/users")
      expect(page).to have_content("Edit")
    end
  end
end
