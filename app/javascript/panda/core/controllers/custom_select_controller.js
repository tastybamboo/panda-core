import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]
  static values = { open: { type: Boolean, default: false }, index: { type: Number, default: -1 } }

  connect() {
    this.element.classList.add("relative")
    this.selectTarget.classList.add("sr-only")
    this.options = Array.from(this.selectTarget.options)
    this.buildUI()
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }

  buildUI() {
    // Find the selected option
    const selectedOption = this.options.find(o => o.selected) || this.options[0]
    const isPlaceholder = selectedOption && (selectedOption.value === "" || selectedOption.disabled)

    // Build trigger button
    this.trigger = document.createElement("button")
    this.trigger.type = "button"
    this.trigger.setAttribute("role", "combobox")
    this.trigger.setAttribute("aria-expanded", "false")
    this.trigger.setAttribute("aria-haspopup", "listbox")
    this.trigger.className = "flex items-center justify-between w-full h-11 rounded-xl border border-gray-200 bg-white px-3 py-2 text-sm text-left focus:border-transparent focus:ring-2 focus:ring-primary-500 cursor-pointer"
    this.trigger.innerHTML = `
      <span class="truncate ${isPlaceholder ? "text-gray-400" : "text-gray-900"}">${this.escapeHtml(selectedOption ? selectedOption.text : "")}</span>
      <svg class="w-4 h-4 text-gray-400 shrink-0 ml-2 transition-transform duration-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
      </svg>
    `
    this.trigger.addEventListener("click", (e) => {
      e.preventDefault()
      this.toggleDropdown()
    })
    this.trigger.addEventListener("keydown", (e) => this.handleTriggerKeydown(e))

    // Build listbox
    this.listbox = document.createElement("ul")
    this.listbox.setAttribute("role", "listbox")
    this.listbox.setAttribute("tabindex", "-1")
    this.listbox.className = "absolute z-50 mt-1 w-full max-h-60 overflow-auto rounded-xl border border-gray-200 bg-white shadow-lg py-1 text-sm focus:outline-none hidden"
    this.listbox.id = `custom-select-listbox-${this.selectTarget.id || Math.random().toString(36).slice(2)}`
    this.trigger.setAttribute("aria-controls", this.listbox.id)

    this.options.forEach((option, i) => {
      const li = document.createElement("li")
      li.setAttribute("role", "option")
      li.setAttribute("aria-selected", option.selected ? "true" : "false")
      li.setAttribute("data-index", i)
      li.setAttribute("data-value", option.value)
      li.id = `${this.listbox.id}-option-${i}`

      const isBlank = option.value === "" || option.disabled
      li.className = `relative cursor-pointer select-none px-3 py-2 flex items-center justify-between ${
        option.selected && !isBlank ? "bg-primary-50 text-primary-800" : "text-gray-900"
      } ${isBlank ? "text-gray-400" : ""}`

      li.innerHTML = `
        <span class="block truncate">${this.escapeHtml(option.text)}</span>
        ${option.selected && !isBlank ? '<i class="fa-solid fa-check text-primary-600 text-xs"></i>' : ""}
      `

      li.addEventListener("click", () => this.selectOption(i))
      li.addEventListener("mouseenter", () => this.highlightOption(i))
      this.listbox.appendChild(li)
    })

    this.listbox.addEventListener("keydown", (e) => this.handleListboxKeydown(e))

    // Insert after the native select
    this.selectTarget.parentNode.insertBefore(this.trigger, this.selectTarget.nextSibling)
    this.selectTarget.parentNode.appendChild(this.listbox)

    // Remove any existing SVG chevron (from the FormBuilder select_svg helper)
    const existingSvg = this.element.querySelector("svg.pointer-events-none")
    if (existingSvg) existingSvg.remove()
  }

  toggleDropdown() {
    this.openValue = !this.openValue
    this.renderDropdown()

    if (this.openValue) {
      // Highlight the currently selected option
      const selectedIdx = this.options.findIndex(o => o.selected)
      if (selectedIdx >= 0) {
        this.indexValue = selectedIdx
        this.highlightOption(selectedIdx)
      }
      this.listbox.focus()
    }
  }

  renderDropdown() {
    if (this.openValue) {
      this.listbox.classList.remove("hidden")
      this.trigger.setAttribute("aria-expanded", "true")
      this.trigger.querySelector("svg").style.transform = "rotate(180deg)"
    } else {
      this.listbox.classList.add("hidden")
      this.trigger.setAttribute("aria-expanded", "false")
      this.trigger.querySelector("svg").style.transform = ""
      this.indexValue = -1
    }
  }

  selectOption(index) {
    const option = this.options[index]
    if (!option) return

    // Update native select
    this.selectTarget.value = option.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))

    // Update trigger text
    const isPlaceholder = option.value === "" || option.disabled
    const triggerText = this.trigger.querySelector("span")
    triggerText.textContent = option.text
    triggerText.className = `truncate ${isPlaceholder ? "text-gray-400" : "text-gray-900"}`

    // Update option styles and aria
    const items = this.listbox.querySelectorAll("[role='option']")
    items.forEach((li, i) => {
      const opt = this.options[i]
      const isBlank = opt.value === "" || opt.disabled
      const isSelected = i === index
      li.setAttribute("aria-selected", isSelected ? "true" : "false")
      li.className = `relative cursor-pointer select-none px-3 py-2 flex items-center justify-between ${
        isSelected && !isBlank ? "bg-primary-50 text-primary-800" : "text-gray-900"
      } ${isBlank ? "text-gray-400" : ""}`
      li.innerHTML = `
        <span class="block truncate">${this.escapeHtml(opt.text)}</span>
        ${isSelected && !isBlank ? '<i class="fa-solid fa-check text-primary-600 text-xs"></i>' : ""}
      `
    })

    // Close
    this.openValue = false
    this.renderDropdown()
    this.trigger.focus()
  }

  highlightOption(index) {
    this.indexValue = index
    const items = this.listbox.querySelectorAll("[role='option']")
    items.forEach((li, i) => {
      if (i === index) {
        li.classList.add("bg-primary-100")
        li.scrollIntoView({ block: "nearest" })
        this.trigger.setAttribute("aria-activedescendant", li.id)
      } else {
        li.classList.remove("bg-primary-100")
      }
    })
  }

  handleTriggerKeydown(event) {
    switch (event.key) {
      case "ArrowDown":
      case "ArrowUp":
      case "Enter":
      case " ":
        event.preventDefault()
        if (!this.openValue) {
          this.openValue = true
          this.renderDropdown()
          const selectedIdx = this.options.findIndex(o => o.selected)
          this.highlightOption(selectedIdx >= 0 ? selectedIdx : 0)
          this.listbox.focus()
        }
        break
      case "Escape":
        if (this.openValue) {
          event.preventDefault()
          this.openValue = false
          this.renderDropdown()
        }
        break
    }
  }

  handleListboxKeydown(event) {
    const maxIndex = this.options.length - 1

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.highlightOption(Math.min(this.indexValue + 1, maxIndex))
        break
      case "ArrowUp":
        event.preventDefault()
        this.highlightOption(Math.max(this.indexValue - 1, 0))
        break
      case "Enter":
      case " ":
        event.preventDefault()
        if (this.indexValue >= 0) {
          this.selectOption(this.indexValue)
        }
        break
      case "Escape":
        event.preventDefault()
        this.openValue = false
        this.renderDropdown()
        this.trigger.focus()
        break
      case "Tab":
        this.openValue = false
        this.renderDropdown()
        break
      default:
        // Type-ahead: jump to first option starting with typed character
        if (event.key.length === 1) {
          const char = event.key.toLowerCase()
          const startIdx = this.indexValue + 1
          const match = this.options.findIndex((o, i) =>
            i >= startIdx && o.text.toLowerCase().startsWith(char)
          )
          if (match >= 0) {
            this.highlightOption(match)
          } else {
            // Wrap around
            const wrapMatch = this.options.findIndex(o =>
              o.text.toLowerCase().startsWith(char)
            )
            if (wrapMatch >= 0) this.highlightOption(wrapMatch)
          }
        }
        break
    }
  }

  handleOutsideClick(event) {
    if (this.openValue && !this.element.contains(event.target)) {
      this.openValue = false
      this.renderDropdown()
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
