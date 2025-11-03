import { Application } from "@hotwired/stimulus"
import "@fortawesome/fontawesome-free"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }

// Note: controllers/index.js must be loaded separately in the HTML to avoid circular dependency
// It will import this application and register all controllers