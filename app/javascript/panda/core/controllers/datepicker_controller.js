import { Controller } from "@hotwired/stimulus"
import { Calendar } from "vanilla-calendar-pro"

export default class extends Controller {
  static targets = ["display", "hidden", "calendar"]
  static values = {
    dateMin: String,
    dateMax: String
  }

  connect() {
    this.isOpen = false
    this.calendar = null
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
    if (this.calendar) this.calendar.destroy()
  }

  toggle(event) {
    event.stopPropagation()
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
          theme: "light"
        },
        iso8601: true,
        selection: {
          day: "single"
        }
      },
      actions: {
        clickDay: (event, self) => {
          this.handleDateSelect(self)
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

    // Set initial selected date from hidden field value
    const currentValue = this.hiddenTarget.value
    if (currentValue && /^\d{4}-\d{2}-\d{2}$/.test(currentValue)) {
      options.selectedDates = [currentValue]
      options.selectedMonth = parseInt(currentValue.split("-")[1], 10) - 1
      options.selectedYear = parseInt(currentValue.split("-")[0], 10)
    }

    this.calendarTarget.innerHTML = ""
    this.calendarTarget.classList.remove("hidden")

    this.calendar = new Calendar(this.calendarTarget, options)
    this.calendar.init()
    this.isOpen = true

    document.addEventListener("click", this.outsideClick)
    document.addEventListener("keydown", this.handleKeydown)
  }

  close() {
    if (!this.isOpen) return
    this.calendarTarget.classList.add("hidden")
    if (this.calendar) {
      this.calendar.destroy()
      this.calendar = null
    }
    this.isOpen = false
    document.removeEventListener("click", this.outsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleDateSelect(calendarInstance) {
    const selectedDates = calendarInstance.context.selectedDates
    if (selectedDates && selectedDates.length > 0) {
      const isoDate = selectedDates[selectedDates.length - 1]
      this.hiddenTarget.value = isoDate
      this.displayTarget.value = this.formatDate(isoDate)
      this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
      this.close()
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
      this.displayTarget.focus()
    }
  }

  formatDate(isoDate) {
    const [year, month, day] = isoDate.split("-")
    const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day))
    return date.toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" })
  }
}
