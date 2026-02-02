import { Controller } from "@hotwired/stimulus"

// Navigation toggle controller for expandable menu items
// Usage:
//   <div data-controller="navigation-toggle">
//     <button data-navigation-toggle-target="button"
//             data-action="click->navigation-toggle#toggle"
//             aria-controls="sub-menu-1"
//             aria-expanded="false">
//       <span>Menu Item</span>
//       <i data-navigation-toggle-target="icon" class="fa-solid fa-chevron-right"></i>
//     </button>
//     <div id="sub-menu-1" data-navigation-toggle-target="menu" class="hidden">
//       <a href="#">Sub Item 1</a>
//       <a href="#">Sub Item 2</a>
//     </div>
//   </div>
export default class extends Controller {
  static targets = ["button", "menu", "icon", "wrapper"]

  connect() {
    // Ensure menu starts in correct state
    // Check if this menu should be expanded by default (if a child is active)
    const hasActiveChild = this.menuTarget.querySelector('[class*="bg-primary-500"]')
    if (hasActiveChild) {
      this.expand()
    } else {
      // Explicitly ensure the menu is collapsed if no active child
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
    this.menuTarget.classList.remove("hidden")
    this.menuTarget.style.display = ""
    this.buttonTarget.setAttribute("aria-expanded", "true")

    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.add("rounded-xl", "bg-white/5", "px-3", "py-2")
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.add("rotate-90")
    }
  }

  collapse() {
    this.menuTarget.classList.add("hidden")
    this.menuTarget.style.display = "none"
    this.buttonTarget.setAttribute("aria-expanded", "false")

    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.remove("rounded-xl", "bg-white/5", "px-3", "py-2")
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-90")
    }
  }
}
