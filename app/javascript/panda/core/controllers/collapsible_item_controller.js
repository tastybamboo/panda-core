import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["body", "icon", "summary"]
  static values = { expanded: { type: Boolean, default: false } }

  connect() {
    this.render()
  }

  toggle(event) {
    // Don't toggle if clicking a button, link, input, or select inside the header
    if (event.target.closest("button, a, input, select, textarea")) return

    this.expandedValue = !this.expandedValue
    this.render()
  }

  // No-op action to stop event propagation from nested buttons
  noop() {}

  render() {
    if (this.hasBodyTarget) {
      if (this.expandedValue) {
        this.bodyTarget.style.maxHeight = this.bodyTarget.scrollHeight + "px"
        this.bodyTarget.style.opacity = "1"
      } else {
        this.bodyTarget.style.maxHeight = "0px"
        this.bodyTarget.style.opacity = "0"
      }
    }

    if (this.hasIconTarget) {
      this.iconTarget.style.transform = this.expandedValue ? "rotate(180deg)" : "rotate(0deg)"
    }
  }

  // Update summary text from a form input event
  updateSummary(event) {
    if (this.hasSummaryTarget) {
      const value = event.target.value.trim()
      this.summaryTarget.textContent = value || this.summaryTarget.dataset.placeholder || "New item"
    }
  }
}
