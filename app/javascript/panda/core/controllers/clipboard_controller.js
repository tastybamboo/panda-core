import { Controller } from "@hotwired/stimulus"

// Handles copy-to-clipboard and reveal/mask for secret values like API tokens.
//
// Usage:
//   <div data-controller="clipboard"
//        data-clipboard-secret-value="the-full-token"
//        data-clipboard-masked-value="true">
//     <span data-clipboard-target="display">...</span>
//     <button data-action="click->clipboard#toggleReveal" data-clipboard-target="revealButton">
//       <i data-clipboard-target="revealIcon" class="fa-solid fa-eye"></i>
//       <span data-clipboard-target="revealText">Reveal</span>
//     </button>
//     <button data-action="click->clipboard#copy" data-clipboard-target="copyButton">
//       <i data-clipboard-target="copyIcon" class="fa-solid fa-copy"></i>
//       <span data-clipboard-target="copyText">Copy</span>
//     </button>
//   </div>
export default class extends Controller {
  static values = {
    secret: String,
    masked: { type: Boolean, default: true }
  }

  static targets = [
    "display",
    "revealButton",
    "revealIcon",
    "revealText",
    "copyButton",
    "copyIcon",
    "copyText"
  ]

  connect() {
    this._feedbackTimeout = null
    this.updateDisplay()
  }

  disconnect() {
    if (this._feedbackTimeout) {
      clearTimeout(this._feedbackTimeout)
      this._feedbackTimeout = null
    }
  }

  toggleReveal() {
    this.maskedValue = !this.maskedValue
    this.updateDisplay()
  }

  updateDisplay() {
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = this.maskedValue ? this.maskedSecret : this.secretValue
    }

    if (this.hasRevealIconTarget) {
      this.revealIconTarget.className = this.maskedValue
        ? "fa-solid fa-eye"
        : "fa-solid fa-eye-slash"
    }

    if (this.hasRevealTextTarget) {
      this.revealTextTarget.textContent = this.maskedValue ? "Reveal" : "Hide"
    }
  }

  copy() {
    navigator.clipboard.writeText(this.secretValue).then(() => {
      this.showCopiedFeedback()
    }).catch((err) => {
      console.error("Failed to copy:", err)
    })
  }

  showCopiedFeedback() {
    if (!this.hasCopyButtonTarget) return

    // Clear any pending feedback timeout from a previous copy
    if (this._feedbackTimeout) {
      clearTimeout(this._feedbackTimeout)
    }

    const button = this.copyButtonTarget
    if (!this._originalClasses) {
      this._originalClasses = button.className
    }

    // Update icon and text
    if (this.hasCopyIconTarget) {
      this.copyIconTarget.className = "fa-solid fa-check"
    }
    if (this.hasCopyTextTarget) {
      this.copyTextTarget.textContent = "Copied!"
    }

    // Swap to success style
    button.className = "shrink-0 btn btn-success transition"

    // Restore after 2 seconds
    this._feedbackTimeout = setTimeout(() => {
      this._feedbackTimeout = null
      button.className = this._originalClasses
      if (this.hasCopyIconTarget) {
        this.copyIconTarget.className = "fa-solid fa-copy"
      }
      if (this.hasCopyTextTarget) {
        this.copyTextTarget.textContent = "Copy"
      }
    }, 2000)
  }

  get maskedSecret() {
    const secret = this.secretValue
    if (!secret || secret.length === 0) return ""
    if (secret.length <= 4) return "\u2022".repeat(secret.length)
    return "\u2022".repeat(12) + secret.slice(-4)
  }
}
