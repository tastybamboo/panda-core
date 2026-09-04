# Content Security Policy

Panda Core's admin renders correctly under a strict policy:

```ruby
# config/initializers/content_security_policy.rb
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
```

No CDN origins are required, and `'unsafe-inline'` is not required in
`script-src`. (It would not help in any case: browsers ignore `'unsafe-inline'`
in a directive that also carries a nonce — a trap worth knowing about on its
own.)

## Why this needed fixing at all

A CSP violation never reaches the server. The tag is in the markup, the browser
drops it, and nothing errors. Losing the importmap this way takes Turbo and
every Stimulus controller with it, and the page looks exactly like one that
simply has no JavaScript — which is why this went unnoticed until a consumer
enforced a policy and lost every interactive control on the sign-in screen.

Regression coverage lives in three places, and all of it is worth keeping:

- `spec/requests/panda/core/content_security_policy_spec.rb` — checks the markup:
  no external asset URLs, a non-empty nonce on every inline `<script>`, exactly
  one importmap.
- `spec/system/panda/core/admin/content_security_policy_spec.rb` — checks what a
  browser does with it. Listens for `securitypolicyviolation` events and asserts
  Stimulus actually booted, which is the only place the real failure shows.
- `spec/dummy/config/initializers/content_security_policy.rb` — puts the whole
  dummy suite under the policy above, so anything added later is covered too.

## What the gem serves from its own origin

Everything in the admin `<head>`, from the `Rack::Static` mount at
`/panda-core-assets` (see `lib/panda/core/engine.rb`):

| Asset | Path |
|---|---|
| Font Awesome CSS | `/panda-core-assets/fontawesome/css/all.min.css` |
| Font Awesome webfonts | `/panda-core-assets/fontawesome/webfonts/*.woff2` |
| es-module-shims | `/panda-core-assets/es-module-shims.js` |
| Core CSS | `/panda-core-assets/panda-core*.css` |
| Vendored JS (Stimulus, Turbo, …) | `/panda/core/vendor/*.js` |

Font Awesome's CSS is the upstream build, unmodified — its `../webfonts/` URLs
resolve against the `css/` directory it is served from.

## Icons render as `<i>`, not `<svg>`

Font Awesome's JavaScript SVG watcher is switched off in
`app/javascript/panda/core/fontawesome-config.js`. It replaced every
`fa-solid` `<i>` with an inline `<svg>` and sized the result with a `<style>` it
injected through `document.head.insertBefore` — with no nonce, because Font
Awesome 7.2.0 has no nonce option at all. Under an enforced `style-src` that
style is dropped and the replaced icons render at raw viewBox size.

The vendored webfont CSS draws the same `fa-solid` / `fa-brands` glyphs from a
`::before` rule with no JavaScript involved, so the watcher is redundant as well
as CSP-hostile. Write icons exactly as before:

```erb
<i class="fa-solid fa-house"></i>
```

If your app has CSS or tests matching `svg[data-icon='…']`, match
`i.fa-solid.fa-…` instead.

## Injecting your own `<head>` content

`config.additional_head_content` is given a view context, so it can read the
nonce. Both shapes work:

```ruby
# Arity 0 — evaluated against the view context.
config.additional_head_content = lambda do
  tag.style("html[data-theme='acme'] { --panda-panel-bg: #123456; }".html_safe,
            nonce: content_security_policy_nonce)
end

# Arity 1 — the view context is yielded.
config.additional_head_content = ->(view) do
  view.javascript_importmap_tags(nonce: view.content_security_policy_nonce)
end
```

A lambda that just returns a string keeps working unchanged.

## If your app emits its own importmap

A document may contain only one: browsers with native import-map support honour
the first and ignore the rest. If your app calls `javascript_importmap_tags`,
do not also call `panda_core_javascript` — merge Panda's pins into your own
importmap and emit only the entry points:

```ruby
# In your own importmap-building code
Panda::Core::ModuleRegistry.combined_importmap  # => { "panda/core/application" => "/panda/core/application.js", ... }
```

```erb
<%= javascript_importmap_tags %>   <%# your importmap, with Panda's pins merged in %>
<%= panda_core_script_tags %>      <%# Panda's module entry points, nonced %>
```

`panda_core_javascript` remains `panda_core_importmap_tag + panda_core_script_tags`
and is still the right call for apps that do not emit an importmap of their own.
