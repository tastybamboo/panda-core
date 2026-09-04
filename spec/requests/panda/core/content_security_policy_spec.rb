# frozen_string_literal: true

require "rails_helper"

# The dummy app enforces a strict CSP (script-src 'self' / style-src 'self' with
# a per-request nonce) — see spec/dummy/config/initializers/content_security_policy.rb.
#
# A CSP violation never reaches the server: the tag is in the markup, the browser
# drops it, and nothing errors. Losing the importmap this way takes Turbo and
# every Stimulus controller with it and looks exactly like a page that simply has
# no JavaScript. These examples are the only place that failure is visible.
RSpec.describe "Content Security Policy compliance", type: :request do
  let(:admin_user) { create_admin_user }

  # Every screen on the admin_simple layout renders Shared::HeaderComponent
  # directly; the admin layout reaches it through MainLayoutComponent.
  {
    "panda/core/admin_simple" => "/admin/login",
    "panda/core/admin" => "/admin"
  }.each do |layout, path|
    describe "a screen on the #{layout} layout (GET #{path})" do
      before do
        post "/admin/test_sessions", params: {user_id: admin_user.id}
        get path
      end

      it "responds successfully" do
        expect(response).to have_http_status(:ok)
      end

      it "loads no scripts, stylesheets or images from an external origin" do
        offenders = external_asset_urls(response.body)

        expect(offenders).to be_empty,
          "expected every asset to be same-origin, found: #{offenders.join(", ")}"
      end

      it "gives every inline <script> a non-empty nonce" do
        inline_scripts = inline_script_tags(response.body)

        # Assert the sample is non-empty first: with no inline scripts at all the
        # nonce expectation below passes vacuously and proves nothing.
        expect(inline_scripts).not_to be_empty,
          "expected the page to emit inline <script> tags (the importmap and the " \
          "module entry points) but found none — the nonce assertion would pass vacuously"

        un_nonced = inline_scripts.reject { |tag| tag["nonce"].present? }

        expect(un_nonced).to be_empty,
          "expected every inline <script> to carry a non-empty nonce, found " \
          "#{un_nonced.size} without one: #{un_nonced.map { |t| t.to_s[0, 120] }.join(" | ")}"
      end

      it "declares its character encoding within the first 1024 bytes" do
        # The HTML spec ignores a charset declaration that lands any later.
        head = response.body.byteslice(0, 1024)

        expect(head).to match(/<meta\s+charset=/i)
      end

      it "declares a document language" do
        html = Nokogiri::HTML5(response.body).at_css("html")

        expect(html["lang"]).to be_present
      end
    end
  end

  describe "the importmap" do
    before do
      post "/admin/test_sessions", params: {user_id: admin_user.id}
      get "/admin"
    end

    it "emits exactly one, so browsers with native support honour the right one" do
      importmaps = Nokogiri::HTML5(response.body).css('script[type="importmap"]')

      expect(importmaps.size).to eq(1)
    end
  end

  # Anything the browser fetches: src/href on script, link and img.
  def external_asset_urls(body)
    doc = Nokogiri::HTML5(body)

    urls = doc.css("script[src]").map { |n| n["src"] } +
      doc.css("link[href]").map { |n| n["href"] } +
      doc.css("img[src]").map { |n| n["src"] }

    urls.compact.select { |url| url.match?(%r{\Ahttps?://}i) }
  end

  def inline_script_tags(body)
    Nokogiri::HTML5(body).css("script").reject { |n| n["src"].present? }
  end
end
