# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Editor Search", type: :request do
  let(:admin_user) { create_admin_user }

  around do |example|
    Panda::Core::SearchRegistry.reset!
    example.run
    Panda::Core::SearchRegistry.reset!
  end

  describe "GET /admin/editor/search" do
    before do
      post "/admin/test_sessions", params: {user_id: admin_user.id}
    end

    it "returns JSON results from registered providers" do
      provider_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/pages/1", name: "Test Page", description: "A test page about #{query}"}]
        end
      end
      Panda::Core::SearchRegistry.register(name: "pages", search_class: provider_class)

      get "/admin/editor/search", params: {search: "hello"}

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(json["items"].length).to eq(1)
      expect(json["items"].first["name"]).to eq("Test Page")
      expect(json["items"].first["href"]).to eq("/pages/1")
    end

    it "returns empty items for blank search query" do
      provider_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/pages/1", name: "Should Not Appear", description: "Nope"}]
        end
      end
      Panda::Core::SearchRegistry.register(name: "pages", search_class: provider_class)

      get "/admin/editor/search", params: {search: ""}

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(json["items"]).to eq([])
    end

    it "returns items from multiple registered providers" do
      pages_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/pages/1", name: "Page Result", description: "A page"}]
        end
      end

      posts_class = Class.new do
        def self.editor_search(query, limit:)
          [{href: "/posts/1", name: "Post Result", description: "A post"}]
        end
      end

      Panda::Core::SearchRegistry.register(name: "pages", search_class: pages_class)
      Panda::Core::SearchRegistry.register(name: "posts", search_class: posts_class)

      get "/admin/editor/search", params: {search: "test"}

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(json["items"].length).to eq(2)
      expect(json["items"].map { |i| i["name"] }).to contain_exactly("Page Result", "Post Result")
    end
  end

  context "when not authenticated" do
    it "redirects to login" do
      get "/admin/editor/search", params: {search: "test"}

      expect(response).to redirect_to(panda_core.admin_login_path)
    end
  end
end
