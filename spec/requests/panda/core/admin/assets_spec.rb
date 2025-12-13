# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin asset loading", type: :request do
  let(:admin_user) { create_admin_user }
  let(:asset_glob) { Panda::Core::Engine.root.join("public", "panda-core-assets", "panda-core-*.css").to_s }

  before do
    sign_in_as(admin_user)
  end

  it "prefers the newest compiled CSS asset when available" do
    allow(Dir).to receive(:[]).and_call_original
    allow(Dir).to receive(:[]).with(asset_glob).and_return([
      "/tmp/panda-core-assets/panda-core-1.css",
      "/tmp/panda-core-assets/panda-core-99.css"
    ])

    allow(File).to receive(:symlink?).and_call_original
    allow(File).to receive(:symlink?).with("/tmp/panda-core-assets/panda-core-1.css").and_return(false)
    allow(File).to receive(:symlink?).with("/tmp/panda-core-assets/panda-core-99.css").and_return(false)

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/panda-core-assets/panda-core-99.css")
  end

  it "falls back to unversioned CSS and importmap when compiled assets are missing" do
    allow(Dir).to receive(:[]).and_call_original
    allow(Dir).to receive(:[]).with(asset_glob).and_return([])

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/panda-core-assets/panda-core.css")
    expect(response.body).to include(%(import "panda/core/application"))
  end
end
