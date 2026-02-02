import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "icon", "wrapper"]

  // Classes toggled on the button when expanding/collapsing
  static expandedButtonClasses = ["rounded-t-xl", "bg-white/15", "text-white"]
  static collapsedButtonClasses = ["rounded-xl", "hover:bg-white/5", "text-white/80"]

  connect() {
    const hasActiveChild = this.menuTarget.querySelector('[class*="bg-primary-500"]')
    if (hasActiveChild) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
    }

    const isExpanded = this.buttonTarget.getAttribute("aria-expanded") === "true"

    if (isExpanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    // Menu animation
    this.menuTarget.classList.remove("max-h-0", "opacity-0")
    this.menuTarget.classList.add("max-h-96", "opacity-100")

    this.buttonTarget.setAttribute("aria-expanded", "true")

    // Button styling: collapsed → expanded
    this.constructor.collapsedButtonClasses.forEach(c => this.buttonTarget.classList.remove(c))
    this.constructor.expandedButtonClasses.forEach(c => this.buttonTarget.classList.add(c))

    // Wrapper background
    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.add("rounded-xl", "bg-white/10", "overflow-hidden")
    }

    // Chevron rotation
    if (this.hasIconTarget) {
      this.iconTarget.classList.add("rotate-90")
    }
  }

  collapse() {
    // Menu animation
    this.menuTarget.classList.remove("max-h-96", "opacity-100")
    this.menuTarget.classList.add("max-h-0", "opacity-0")

    this.buttonTarget.setAttribute("aria-expanded", "false")

    // Button styling: expanded → collapsed
    this.constructor.expandedButtonClasses.forEach(c => this.buttonTarget.classList.remove(c))
    this.constructor.collapsedButtonClasses.forEach(c => this.buttonTarget.classList.add(c))

    // Wrapper background
    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.remove("rounded-xl", "bg-white/10", "overflow-hidden")
    }

    // Chevron rotation
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-90")
    }
  }
}
