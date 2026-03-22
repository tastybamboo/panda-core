# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Import Sessions", type: :request do
  let(:admin_user) { create_admin_user }

  before do
    unless Panda::Core::User.include?(Panda::Core::Importable)
      Panda::Core::User.include(Panda::Core::Importable)
    end
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "GET /admin/import_sessions" do
    it "renders the index page" do
      get "/admin/import_sessions"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/import_sessions/new" do
    it "renders the new import form" do
      get "/admin/import_sessions/new", params: {importable_type: "Panda::Core::User"}
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/import_sessions" do
    it "rejects requests without a file" do
      post "/admin/import_sessions", params: {importable_type: "Panda::Core::User"}
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects XLS files" do
      file = Rack::Test::UploadedFile.new(StringIO.new("data"), "application/vnd.ms-excel", false, original_filename: "data.xls")
      post "/admin/import_sessions", params: {importable_type: "Panda::Core::User", import_file: file}
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates an import session with a CSV file" do
      csv_content = "name,email\nAlice,alice@example.com\n"
      file = Rack::Test::UploadedFile.new(StringIO.new(csv_content), "text/csv", false, original_filename: "users.csv")

      expect {
        post "/admin/import_sessions", params: {importable_type: "Panda::Core::User", import_file: file}
      }.to change(Panda::Core::ImportSession, :count).by(1)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /admin/import_sessions/:id" do
    it "renders the show page" do
      csv_content = "name,email\nAlice,alice@example.com\n"
      import_session = Panda::Core::ImportSession.create!(
        importable_type: "Panda::Core::User",
        user: admin_user,
        status: "mapping"
      )
      import_session.import_file.attach(
        io: StringIO.new(csv_content),
        filename: "test.csv",
        content_type: "text/csv"
      )

      get "/admin/import_sessions/#{import_session.id}"
      expect(response).to have_http_status(:ok)
    end
  end
end
