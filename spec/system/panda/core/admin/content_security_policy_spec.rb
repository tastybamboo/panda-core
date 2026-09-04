# frozen_string_literal: true

require "system_helper"

# The request spec (spec/requests/panda/core/content_security_policy_spec.rb)
# checks the markup. This checks what a browser actually does with it, which is
# the only place the real failure is observable: a CSP violation never reaches
# the server, so a dropped importmap looks exactly like a page that has no
# JavaScript, and a dropped stylesheet looks like a page with no icons.
RSpec.describe "Content Security Policy in the browser", type: :system do
  let(:admin_user) { create_admin_user }

  # Collect violations as they happen. A listener installed after load would miss
  # the ones raised while the document was parsing, which is all of them, so this
  # is injected before navigation via addScriptToEvaluateOnNewDocument.
  def collect_violations!
    page.driver.browser.page.command(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JS
        window.__cspViolations = [];
        document.addEventListener("securitypolicyviolation", (e) => {
          window.__cspViolations.push(
            e.violatedDirective + " blocked " + (e.blockedURI || "inline")
          );
        });
      JS
    )
  end

  def violations
    page.evaluate_script("window.__cspViolations || []")
  end

  describe "the login page (admin_simple layout)" do
    it "raises no CSP violations and boots Stimulus" do
      collect_violations!
      visit "/admin/login"

      expect(page).to have_css("body")
      expect(violations).to be_empty

      # The importmap is what carries Turbo and every Stimulus controller. When
      # it is dropped, this is nil and nothing else on the page reports a thing.
      expect(page).to have_css("html")
      expect(page.evaluate_script("typeof window.Stimulus")).to eq("object")
    end
  end

  describe "the admin dashboard (admin layout)" do
    before { login_with_google(admin_user) }

    it "raises no CSP violations and boots Stimulus" do
      collect_violations!
      visit "/admin"

      expect(page).to have_css("body")
      expect(violations).to be_empty
      expect(page.evaluate_script("typeof window.Stimulus")).to eq("object")
    end

    it "loads the Font Awesome webfont stylesheet" do
      visit "/admin"

      # A stylesheet the browser refused is still in document.styleSheets, but
      # with no readable rules — so count the rules, not the <link>.
      rule_count = page.evaluate_script(<<~JS)
        Array.from(document.styleSheets)
          .filter((s) => (s.href || "").includes("fontawesome"))
          .reduce((n, s) => {
            try { return n + s.cssRules.length } catch (e) { return n }
          }, 0)
      JS

      expect(rule_count).to be > 0
    end
  end
end
