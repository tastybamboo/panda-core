import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    dismissAfter: Number
  }

  connect() {
    // Auto-dismiss if dismissAfter value is set
    if (this.hasDismissAfterValue && this.dismissAfterValue > 0) {
      this.timeout = setTimeout(() => {
        this.close()
      }, this.dismissAfterValue)
    }
  }

  disconnect() {
    // Clean up timeout if controller is disconnected
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  close() {
    // Clear any pending timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Remove the element with a fade-out animation
    this.element.style.transition = "opacity 0.3s ease-out"
    this.element.style.opacity = "0"

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
