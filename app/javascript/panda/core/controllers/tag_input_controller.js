import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "selected", "hiddenInputs"]
  static values = { url: String, selected: { type: Array, default: [] } }

  connect() {
    this.selectedIds = new Set(this.selectedValue.map(t => t.id))
    this.debounceTimer = null
    this.highlightIndex = -1

    // Close on outside click
    this.outsideClickHandler = (e) => {
      if (!this.element.contains(e.target)) this.hideResults()
    }
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  search() {
    clearTimeout(this.debounceTimer)
    const query = this.inputTarget.value.trim()

    if (query.length < 1) {
      this.hideResults()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchResults(query), 200)
  }

  async fetchResults(query) {
    try {
      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })
      const tags = await response.json()

      // Filter out already selected
      const available = tags.filter(t => !this.selectedIds.has(t.id))
      this.renderResults(available, query)
    } catch (e) {
      console.error("[tag-input] fetch error:", e)
    }
  }

  renderResults(tags, query) {
    this.highlightIndex = -1

    if (tags.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-3 py-2 text-sm text-gray-500">No tags found</div>
      `
    } else {
      this.resultsTarget.innerHTML = tags.map((tag, i) => `
        <button type="button"
                class="flex items-center gap-2 w-full px-3 py-2 text-sm text-left hover:bg-gray-50 focus:bg-gray-50"
                data-action="click->tag-input#selectTag"
                data-tag-id="${tag.id}"
                data-tag-name="${this.escapeAttr(tag.name)}"
                data-tag-colour="${this.escapeAttr(tag.colour)}">
          <span class="w-3 h-3 rounded-full flex-shrink-0" style="background-color: ${this.escapeAttr(tag.colour)}"></span>
          ${this.escapeHtml(tag.name)}
        </button>
      `).join("")
    }

    this.resultsTarget.classList.remove("hidden")
  }

  selectTag(event) {
    const btn = event.currentTarget
    const id = btn.dataset.tagId
    const name = btn.dataset.tagName
    const colour = btn.dataset.tagColour

    if (this.selectedIds.has(id)) return

    this.selectedIds.add(id)
    this.addPill(id, name, colour)
    this.addHiddenInput(id)
    this.inputTarget.value = ""
    this.hideResults()
    this.inputTarget.focus()
  }

  removeTag(event) {
    const id = event.currentTarget.dataset.tagId

    this.selectedIds.delete(id)

    // Remove pill
    const pill = this.selectedTarget.querySelector(`[data-tag-id="${id}"]`)
    if (pill) pill.remove()

    // Remove hidden input
    const input = this.hiddenInputsTarget.querySelector(`[data-tag-id="${id}"]`)
    if (input) input.remove()
  }

  keydown(event) {
    const items = this.resultsTarget.querySelectorAll("button")

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.highlightIndex = Math.min(this.highlightIndex + 1, items.length - 1)
        this.updateHighlight(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.highlightIndex = Math.max(this.highlightIndex - 1, 0)
        this.updateHighlight(items)
        break
      case "Enter":
        event.preventDefault()
        if (this.highlightIndex >= 0 && items[this.highlightIndex]) {
          items[this.highlightIndex].click()
        }
        break
      case "Escape":
        this.hideResults()
        break
    }
  }

  updateHighlight(items) {
    items.forEach((item, i) => {
      item.classList.toggle("bg-gray-50", i === this.highlightIndex)
    })
  }

  addPill(id, name, colour) {
    const pill = document.createElement("span")
    pill.dataset.tagId = id
    pill.className = "inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium"
    pill.style.backgroundColor = `${colour}1a`
    pill.style.color = colour
    pill.style.border = `1px solid ${colour}33`
    pill.innerHTML = `
      ${this.escapeHtml(name)}
      <button type="button" class="ml-0.5 hover:opacity-70" data-action="tag-input#removeTag" data-tag-id="${id}">&times;</button>
    `
    this.selectedTarget.appendChild(pill)
  }

  addHiddenInput(id) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = this.element.querySelector("[name]")?.name || "tag_ids[]"
    input.value = id
    input.dataset.tagId = id
    this.hiddenInputsTarget.appendChild(input)
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden")
    this.highlightIndex = -1
  }

  escapeHtml(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }

  escapeAttr(str) {
    if (!str) return ""
    return str.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/'/g, "&#39;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
