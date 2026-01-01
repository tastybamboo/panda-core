# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin asset loading", type: :request do
  let(:admin_user) { create_admin_user }
  # Use Pathname to match what the code actually passes to Dir[]
  let(:asset_glob) { Panda::Core::Engine.root.join("public", "panda-core-assets", "panda-core-*.css") }
  let(:assets_dir) { Panda::Core::Engine.root.join("public", "panda-core-assets") }

  before do
    # Stub authentication since these tests are about CSS asset loading, not auth
    # In Ruby 4.0.0, session data doesn't persist properly between before block and request
    allow_any_instance_of(Panda::Core::Admin::BaseController).to receive(:authenticate_admin_user!)
    allow_any_instance_of(Panda::Core::Admin::BaseController).to receive(:current_user).and_return(admin_user)
  end

  it "prefers the newest compiled CSS asset when available" do
    mock_css_files = [
      assets_dir.join("panda-core-1.css").to_s,
      assets_dir.join("panda-core-99.css").to_s
    ]

    allow(Dir).to receive(:[]).and_call_original
    allow(Dir).to receive(:[]).with(asset_glob).and_return(mock_css_files)

    allow(File).to receive(:symlink?).and_call_original
    mock_css_files.each do |file|
      allow(File).to receive(:symlink?).with(file).and_return(false)
    end

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/panda-core-assets/panda-core-99.css")
  end

  it "falls back to unversioned CSS and importmap when compiled assets are missing" do
    allow(Dir).to receive(:[]).and_call_original
    allow(Dir).to receive(:[]).with(asset_glob).and_return([])

    # Also need to stub File.exist? for the fallback unversioned file check
    unversioned_css = assets_dir.join("panda-core.css")
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(unversioned_css).and_return(true)

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/panda-core-assets/panda-core.css")
    expect(response.body).to include(%(import "panda/core/application"))
  end
end
