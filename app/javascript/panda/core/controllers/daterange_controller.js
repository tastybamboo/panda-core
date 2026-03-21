import { Controller } from "@hotwired/stimulus"
import { Calendar } from "vanilla-calendar-pro"

export default class extends Controller {
  static targets = ["startInput", "endInput", "calendar"]
  static values = {
    dateMin: String,
    dateMax: String
  }

  connect() {
    this.isOpen = false
    this.calendar = null
    this.activeInput = null

    this.startInputTarget.readOnly = true
    this.endInputTarget.readOnly = true
    this.startInputTarget.style.cursor = "pointer"
    this.endInputTarget.style.cursor = "pointer"

    this.startInputTarget.addEventListener("click", this.openFromStart)
    this.startInputTarget.addEventListener("focus", this.openFromStart)
    this.endInputTarget.addEventListener("click", this.openFromEnd)
    this.endInputTarget.addEventListener("focus", this.openFromEnd)
    document.addEventListener("click", this.outsideClick)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    this.startInputTarget.removeEventListener("click", this.openFromStart)
    this.startInputTarget.removeEventListener("focus", this.openFromStart)
    this.endInputTarget.removeEventListener("click", this.openFromEnd)
    this.endInputTarget.removeEventListener("focus", this.openFromEnd)
    document.removeEventListener("click", this.outsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
    if (this.calendar) this.calendar.destroy()
  }

  openFromStart = (event) => {
    event.stopPropagation()
    this.activeInput = "start"
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  openFromEnd = (event) => {
    event.stopPropagation()
    this.activeInput = "end"
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (this.isOpen) return

    const options = {
      type: "default",
      settings: {
        visibility: {
          theme: "light",
          positionToInput: "auto"
        },
        iso8601: true,
        selection: {
          day: "multiple-ranged"
        }
      },
      actions: {
        clickDay: (event, self) => {
          this.handleRangeSelect(self)
        }
      }
    }

    if (this.hasDateMinValue) {
      options.settings.range = options.settings.range || {}
      options.settings.range.min = this.dateMinValue
    }
    if (this.hasDateMaxValue) {
      options.settings.range = options.settings.range || {}
      options.settings.range.max = this.dateMaxValue
    }

    // Set initial selected range from input values
    const startDate = this.parseInputDate(this.startInputTarget.value)
    const endDate = this.parseInputDate(this.endInputTarget.value)
    if (startDate && endDate) {
      options.selectedDates = this.getDateRange(startDate, endDate)
      options.selectedMonth = parseInt(startDate.split("-")[1], 10) - 1
      options.selectedYear = parseInt(startDate.split("-")[0], 10)
    } else if (startDate) {
      options.selectedDates = [startDate]
      options.selectedMonth = parseInt(startDate.split("-")[1], 10) - 1
      options.selectedYear = parseInt(startDate.split("-")[0], 10)
    }

    this.calendarTarget.innerHTML = ""
    this.calendarTarget.classList.remove("hidden")

    this.calendar = new Calendar(this.calendarTarget, options)
    this.calendar.init()
    this.isOpen = true
  }

  close() {
    if (!this.isOpen) return
    this.calendarTarget.classList.add("hidden")
    if (this.calendar) {
      this.calendar.destroy()
      this.calendar = null
    }
    this.isOpen = false
  }

  handleRangeSelect(calendarInstance) {
    const selectedDates = calendarInstance.context.selectedDates
    if (selectedDates && selectedDates.length > 0) {
      const sorted = [...selectedDates].sort()
      const startDate = sorted[0]
      const endDate = sorted[sorted.length - 1]

      this.startInputTarget.value = this.formatDate(startDate)
      this.endInputTarget.value = this.formatDate(endDate)

      this.startInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      this.endInputTarget.dispatchEvent(new Event("change", { bubbles: true }))

      // Close after selecting end of range (2+ dates selected)
      if (selectedDates.length >= 2) {
        this.close()
      }
    }
  }

  outsideClick = (event) => {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown = (event) => {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
      if (this.activeInput === "end") {
        this.endInputTarget.focus()
      } else {
        this.startInputTarget.focus()
      }
    }
  }

  getDateRange(start, end) {
    const dates = []
    const current = new Date(start)
    const endDate = new Date(end)
    while (current <= endDate) {
      dates.push(current.toISOString().split("T")[0])
      current.setDate(current.getDate() + 1)
    }
    return dates
  }

  parseInputDate(value) {
    if (!value) return null
    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value

    const ukMatch = value.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/)
    if (ukMatch) {
      return `${ukMatch[3]}-${ukMatch[2].padStart(2, "0")}-${ukMatch[1].padStart(2, "0")}`
    }

    const months = { Jan: "01", Feb: "02", Mar: "03", Apr: "04", May: "05", Jun: "06",
                     Jul: "07", Aug: "08", Sep: "09", Oct: "10", Nov: "11", Dec: "12" }
    const namedMatch = value.match(/^(\d{1,2})\s+(\w{3})\s+(\d{4})$/)
    if (namedMatch && months[namedMatch[2]]) {
      return `${namedMatch[3]}-${months[namedMatch[2]]}-${namedMatch[1].padStart(2, "0")}`
    }

    return null
  }

  formatDate(isoDate) {
    const [year, month, day] = isoDate.split("-")
    const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day))
    return date.toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" })
  }
}
