import { Controller } from "@hotwired/stimulus"

// Handles clickable table rows that contain a block-link anchor.
//
// Uses event delegation on the table container rather than CSS ::after
// pseudo-elements, which don't work reliably with display: table-row
// in Safari (position: relative on table-row is undefined per spec).
export default class extends Controller {
  click(event) {
    // Don't interfere with actual links (except block-link) or buttons
    if (event.target.closest("a:not(.block-link), button, input")) return

    const row = event.target.closest(".table-row")
    if (!row) return

    const link = row.querySelector("a.block-link")
    if (!link) return

    event.preventDefault()

    if (typeof Turbo !== "undefined") {
      Turbo.visit(link.href)
    } else {
      window.location.href = link.href
    }
  }
}
