# frozen_string_literal: true

require "rails_helper"

# Proves the bring-your-own-theme injection path end to end: a host app
# registers a theme name via config (available_themes / default_theme) and
# supplies its html[data-theme='...'] variable block via
# additional_head_content; the gem stamps data-theme on <html> and renders
# the injected block in <head> — including on the login page (admin_simple
# layout), which is the surface an unauthenticated visitor sees.
RSpec.describe "host-app theme injection", type: :request do
  around do |example|
    config = Panda::Core.config
    original_themes = config.available_themes
    original_default = config.default_theme
    original_head = config.additional_head_content

    config.available_themes = [["Default", "default"], ["Acme", "acme"]]
    config.default_theme = "acme"
    config.additional_head_content = -> {
      "<style>html[data-theme='acme'] { --panda-panel-bg: #123456; }</style>"
    }

    example.run
  ensure
    config.available_themes = original_themes
    config.default_theme = original_default
    config.additional_head_content = original_head
  end

  it "stamps the configured default theme as data-theme on the login page (no signed-in user)" do
    get "/admin/login"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-theme="acme"')
  end

  it "renders the host app's injected theme stylesheet in the <head> of the login page" do
    get "/admin/login"

    expect(response.body).to include("html[data-theme='acme'] { --panda-panel-bg: #123456; }")
  end

  it "prefers the signed-in user's current_theme over the configured default" do
    user = create_admin_user
    user.update!(current_theme: "default")
    post "/admin/test_sessions", params: {user_id: user.id}

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-theme="default"')
  end
end
