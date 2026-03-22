# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Tags", type: :request do
  let(:admin_user) { create_admin_user }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "GET /admin/tags" do
    it "renders the tags index" do
      Panda::Core::Tag.create!(name: "Priority")
      get "/admin/tags"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Priority")
    end
  end

  describe "GET /admin/tags.json" do
    it "returns tags as JSON" do
      Panda::Core::Tag.create!(name: "Urgent", colour: "#ff0000")
      get "/admin/tags", headers: {"Accept" => "application/json"}
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first["name"]).to eq("Urgent")
      expect(json.first["colour"]).to eq("#ff0000")
    end

    it "filters tags by name" do
      Panda::Core::Tag.create!(name: "Urgent")
      Panda::Core::Tag.create!(name: "Low Priority")
      get "/admin/tags", params: {q: "urg"}, headers: {"Accept" => "application/json"}
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq("Urgent")
    end
  end

  describe "GET /admin/tags/new" do
    it "renders the new tag form" do
      get "/admin/tags/new"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/tags" do
    context "with valid params" do
      it "creates a tag and redirects" do
        expect {
          post "/admin/tags", params: {tag: {name: "Important", colour: "#00ff00"}}
        }.to change(Panda::Core::Tag, :count).by(1)

        expect(response).to redirect_to("/admin/tags")
        expect(flash[:success]).to include("Tag created")
      end
    end

    context "with invalid params" do
      it "renders the new form with errors" do
        post "/admin/tags", params: {tag: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /admin/tags/:id/edit" do
    it "renders the edit form" do
      tag = Panda::Core::Tag.create!(name: "Edit Me")
      get "/admin/tags/#{tag.id}/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit Me")
    end
  end

  describe "PATCH /admin/tags/:id" do
    it "updates the tag and redirects" do
      tag = Panda::Core::Tag.create!(name: "Old Name")
      patch "/admin/tags/#{tag.id}", params: {tag: {name: "New Name"}}
      expect(response).to redirect_to("/admin/tags")
      expect(tag.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /admin/tags/:id" do
    it "destroys the tag and redirects" do
      tag = Panda::Core::Tag.create!(name: "Delete Me")
      expect {
        delete "/admin/tags/#{tag.id}"
      }.to change(Panda::Core::Tag, :count).by(-1)
      expect(response).to redirect_to("/admin/tags")
    end
  end
end
