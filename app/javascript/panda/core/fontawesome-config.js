// Font Awesome's JavaScript renders icons by replacing every
// <i class="fa-solid ..."> with an inline <svg>, and sizes the result with a
// <style> element it injects through document.head.insertBefore. That style
// carries no nonce, and Font Awesome 7.2.0 has no nonce option at all — grep the
// vendored build and there is not one occurrence. Under an enforced
// style-src 'self' the browser drops it silently and every replaced icon renders
// at raw viewBox size.
//
// Panda serves the Font Awesome webfont CSS (see the <link> in
// Shared::HeaderComponent), which draws the same fa-solid / fa-brands glyphs
// from a ::before rule with no JavaScript involved. The SVG watcher is therefore
// redundant as well as CSP-hostile, so it is switched off here — the icons
// consumers write keep resolving, through the CSS instead.
//
// This lives in its own module rather than at the top of application.js because
// ES module dependencies are evaluated before the importing module's own body
// runs: an assignment inside application.js would land *after* Font Awesome had
// already read its config. A module imported ahead of it does not.
window.FontAwesomeConfig = {
  autoReplaceSvg: false,
  autoAddCss: false,
  observeMutations: false
}
