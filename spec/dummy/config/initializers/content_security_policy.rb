# frozen_string_literal: true

# A strict Content Security Policy, matching what a security-conscious consumer
# enforces. It is configured here rather than inside a single spec so that the
# whole dummy suite — system specs driving a real browser included — runs under
# it: a CSP violation is invisible to the server, so the only way the engine
# finds out it emits un-servable markup is by rendering under a policy.
#
# script-src / style-src are 'self' with a per-request nonce and no CDN origins.
# Adding an origin here to make a tag load would defeat the point of the policy.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
    policy.connect_src :self
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
