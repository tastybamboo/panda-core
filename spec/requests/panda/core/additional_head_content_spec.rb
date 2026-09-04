# frozen_string_literal: true

require "rails_helper"

# Panda::Core.config.additional_head_content used to be invoked as a bare .call
# with no receiver and no arguments. A host app's lambda therefore ran with no
# view context and no request, so content_security_policy_nonce was nil inside
# it — and anything the app injected through the hook (javascript_importmap_tags
# included) came out un-nonced and was dropped by a strict script-src.
#
# The dummy app enforces such a policy; see
# spec/dummy/config/initializers/content_security_policy.rb.
RSpec.describe "additional_head_content view context", type: :request do
  def with_head_content(callable)
    config = Panda::Core.config
    original = config.additional_head_content
    config.additional_head_content = callable
    yield
  ensure
    config.additional_head_content = original
  end

  describe "an arity-0 lambda" do
    it "is evaluated against the view context, so it can read the nonce" do
      with_head_content(-> { %(<style nonce="#{content_security_policy_nonce}">/* injected */</style>) }) do
        get "/admin/login"
      end

      expect(response).to have_http_status(:ok)
      nonce = response.body[/<meta name="csp-nonce" content="([^"]+)"/, 1]

      expect(nonce).to be_present
      expect(response.body).to include(%(<style nonce="#{nonce}">/* injected */</style>))
    end

    it "can reach ordinary view helpers" do
      with_head_content(-> { tag.meta(name: "injected-by", content: "host-app") }) do
        get "/admin/login"
      end

      expect(response.body).to include('name="injected-by"')
    end

    # The hook predates this change and host apps pass plain HTML-returning
    # lambdas; those must keep working untouched.
    it "still renders a lambda that just returns a string" do
      with_head_content(-> { "<meta name='legacy' content='yes'>" }) do
        get "/admin/login"
      end

      expect(response.body).to include("name='legacy'")
    end
  end

  describe "an arity-1 lambda" do
    it "is yielded the view context as an argument" do
      callable = ->(view) { %(<style nonce="#{view.content_security_policy_nonce}">/* yielded */</style>) }

      with_head_content(callable) { get "/admin/login" }

      nonce = response.body[/<meta name="csp-nonce" content="([^"]+)"/, 1]

      expect(nonce).to be_present
      expect(response.body).to include(%(<style nonce="#{nonce}">/* yielded */</style>))
    end
  end

  describe "when nothing is configured" do
    it "renders the page without the hook" do
      with_head_content(nil) { get "/admin/login" }

      expect(response).to have_http_status(:ok)
    end
  end
end
