import { Controller } from "@hotwired/stimulus"

// Toggle controller for showing/hiding elements
// Usage:
//   <div data-controller="toggle">
//     <button data-action="click->toggle#toggle">Toggle</button>
//     <div data-toggle-target="toggleable" class="hidden">Content</div>
//   </div>
export default class extends Controller {
  static targets = ["toggleable"]

  toggle(event) {
    if (event) {
      event.preventDefault()
    }

    this.toggleableTargets.forEach(target => {
      target.classList.toggle("hidden")
    })
  }

  show(event) {
    if (event) {
      event.preventDefault()
    }

    this.toggleableTargets.forEach(target => {
      target.classList.remove("hidden")
    })
  }

  hide(event) {
    if (event) {
      event.preventDefault()
    }

    this.toggleableTargets.forEach(target => {
      target.classList.add("hidden")
    })
  }
}
