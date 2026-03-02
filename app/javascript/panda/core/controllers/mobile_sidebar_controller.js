import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop", "hamburger"]

  connect() {
    this._isOpen = false
    this._mediaQuery = window.matchMedia("(min-width: 1024px)")
    this._handleBreakpoint = this._handleBreakpoint.bind(this)
    this._mediaQuery.addEventListener("change", this._handleBreakpoint)
  }

  disconnect() {
    this._mediaQuery.removeEventListener("change", this._handleBreakpoint)
  }

  toggle() {
    if (this._isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this._isOpen = true
    this.sidebarTarget.classList.remove("max-h-16")
    this.sidebarTarget.classList.add("max-h-screen")
    this.backdropTarget.classList.remove("hidden")
    this.hamburgerTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this._isOpen = false
    this.sidebarTarget.classList.remove("max-h-screen")
    this.sidebarTarget.classList.add("max-h-16")
    this.backdropTarget.classList.add("hidden")
    this.hamburgerTarget.setAttribute("aria-expanded", "false")
  }

  _handleBreakpoint(event) {
    if (event.matches && this._isOpen) {
      this.close()
    }
  }
}
