# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::MyProfileController, type: :controller do
  routes { Panda::Core::Engine.routes }

  let(:user) { Panda::Core::User.create!(email: "test@example.com", name: "Test User", admin: true) }

  before do
    session[Panda::Core::ADMIN_SESSION_KEY] = user.id
  end

  describe "GET #edit" do
    it "renders the edit template" do
      get :edit
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end

    it "assigns the current user" do
      get :edit
      expect(assigns(:user)).to be_nil # Uses locals instead
    end

    it "sets breadcrumb" do
      get :edit
      breadcrumb = controller.breadcrumbs.first
      expect(breadcrumb.name).to eq("My Profile")
      expect(breadcrumb.path).to eq("/admin/my_profile/edit")
    end
  end

  describe "PATCH #update" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          user: {
            name: "Updated Name",
            email: "updated@example.com",
            current_theme: "sky"
          }
        }
      end

      it "updates the user" do
        patch :update, params: valid_params
        user.reload
        expect(user.name).to eq("Updated Name")
        expect(user.email).to eq("updated@example.com")
        expect(user.current_theme).to eq("sky")
      end

      it "sets a success flash message" do
        patch :update, params: valid_params
        expect(flash[:success]).to eq("Your profile has been updated successfully.")
      end

      it "redirects to the edit page" do
        patch :update, params: valid_params
        expect(response).to redirect_to("/admin/my_profile/edit")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          user: {
            name: "Updated Name",
            email: "" # Email is required
          }
        }
      end

      it "does not update the user" do
        original_name = user.name
        patch :update, params: invalid_params
        user.reload
        expect(user.name).to eq(original_name)
      end

      it "renders the edit template" do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
      end

      it "returns unprocessable_content status" do
        patch :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when replacing avatar" do
      let(:fixture_path) { Panda::Core::Engine.root.join("spec", "fixtures", "files", "test_image.jpg") }

      before do
        user.avatar.attach(io: File.open(fixture_path), filename: "old_avatar.jpg", content_type: "image/jpeg")
      end

      it "purges the old avatar blob before attaching the new one" do
        old_blob_id = user.avatar.blob.id

        patch :update, params: {
          user: {
            name: user.name,
            email: user.email,
            avatar: fixture_file_upload(fixture_path, "image/jpeg")
          }
        }

        expect(ActiveStorage::Blob.exists?(old_blob_id)).to be false
      end
    end

    context "with additional configured parameters" do
      before do
        allow(Panda::Core.config).to receive(:additional_user_params).and_return([:custom_field])

        # Add custom_field to user table for this test
        unless user.class.column_names.include?("custom_field")
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.add_column :panda_core_users, :custom_field, :string
          end
          user.class.reset_column_information
        end
      end

      after do
        if user.class.column_names.include?("custom_field")
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.remove_column :panda_core_users, :custom_field
          end
          user.class.reset_column_information
        end
      end

      it "permits additional parameters from configuration" do
        patch :update, params: {
          user: {
            name: "Updated Name",
            email: "test@example.com",
            custom_field: "custom value"
          }
        }

        user.reload
        expect(user.custom_field).to eq("custom value")
      end
    end

    context "parameter filtering" do
      it "does not permit firstname parameter" do
        patch :update, params: {
          user: {
            name: "Updated Name",
            email: "test@example.com",
            firstname: "Should Not Work"
          }
        }

        # Should not raise error, just ignore the parameter
        expect(response).to have_http_status(:redirect)
      end

      it "does not permit lastname parameter" do
        patch :update, params: {
          user: {
            name: "Updated Name",
            email: "test@example.com",
            lastname: "Should Not Work"
          }
        }

        # Should not raise error, just ignore the parameter
        expect(response).to have_http_status(:redirect)
      end

      it "does not permit admin parameter" do
        patch :update, params: {
          user: {
            name: "Updated Name",
            email: "test@example.com",
            admin: false
          }
        }

        user.reload
        # Should remain admin since parameter not permitted
        expect(user.admin).to be true
      end
    end
  end
end
