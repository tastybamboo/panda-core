import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "group"]
  static values = {
    url: String,
    open: { type: Boolean, default: false },
    index: { type: Number, default: -1 }
  }

  connect() {
    this.debounceTimer = null
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleGlobalKeydown = this.handleGlobalKeydown.bind(this)
    document.addEventListener("click", this.handleOutsideClick)
    document.addEventListener("keydown", this.handleGlobalKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleGlobalKeydown)
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  // Cmd+K / Ctrl+K to focus search
  handleGlobalKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }

  onInput() {
    const query = this.inputTarget.value.trim()

    if (this.debounceTimer) clearTimeout(this.debounceTimer)

    if (query.length < 2) {
      this.close()
      return
    }

    this.debounceTimer = setTimeout(() => this.search(query), 200)
  }

  async search(query) {
    try {
      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) return

      const data = await response.json()
      this.renderResults(data.groups)
    } catch (e) {
      console.warn("[panda-core] Search failed:", e)
    }
  }

  renderResults(groups) {
    const container = this.resultsTarget

    if (!groups || groups.length === 0) {
      container.innerHTML = `
        <div class="px-4 py-6 text-center text-sm text-white/50">
          No results found
        </div>
      `
      this.open()
      return
    }

    let html = ""
    groups.forEach(group => {
      const icon = group.icon ? `<i class="${this.escapeAttr(group.icon)} mr-1.5"></i>` : ""
      html += `<div class="px-3 pt-3 pb-1"><span class="text-xs font-semibold text-white/40 uppercase tracking-wider">${icon}${this.escapeHtml(group.name)}</span></div>`

      group.results.forEach(result => {
        const desc = result.description
          ? `<span class="text-xs text-white/40 truncate">${this.escapeHtml(result.description)}</span>`
          : ""
        html += `
          <a href="${this.escapeAttr(result.href)}" class="search-result flex flex-col gap-0.5 px-3 py-2 rounded-lg hover:bg-white/10 transition-colors cursor-pointer" data-action="keydown->global-search#onResultKeydown">
            <span class="text-sm text-white/90 truncate">${this.escapeHtml(result.name)}</span>
            ${desc}
          </a>
        `
      })
    })

    container.innerHTML = html
    this.indexValue = -1
    this.open()
  }

  open() {
    this.resultsTarget.classList.remove("hidden")
    this.openValue = true
  }

  close() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
    this.openValue = false
    this.indexValue = -1
  }

  onInputKeydown(event) {
    if (!this.openValue) return

    const results = this.resultsTarget.querySelectorAll(".search-result")
    if (results.length === 0) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.indexValue = Math.min(this.indexValue + 1, results.length - 1)
        this.highlightResult(results)
        break
      case "ArrowUp":
        event.preventDefault()
        this.indexValue = Math.max(this.indexValue - 1, 0)
        this.highlightResult(results)
        break
      case "Enter":
        event.preventDefault()
        if (this.indexValue >= 0 && results[this.indexValue]) {
          results[this.indexValue].click()
        }
        break
      case "Escape":
        event.preventDefault()
        this.close()
        this.inputTarget.blur()
        break
    }
  }

  onResultKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.inputTarget.focus()
    }
  }

  highlightResult(results) {
    results.forEach((el, i) => {
      if (i === this.indexValue) {
        el.classList.add("bg-white/10")
        el.scrollIntoView({ block: "nearest" })
      } else {
        el.classList.remove("bg-white/10")
      }
    })
  }

  onFocus() {
    // If there are already results rendered, show them
    if (this.resultsTarget.innerHTML.trim() !== "") {
      this.open()
    }
  }

  handleOutsideClick(event) {
    if (this.openValue && !this.element.contains(event.target)) {
      this.close()
    }
  }

  escapeHtml(text) {
    if (!text) return ""
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  escapeAttr(text) {
    if (!text) return ""
    return text.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/'/g, "&#39;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
