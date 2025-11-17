import { Application } from '@hotwired/stimulus'
import '@fortawesome/fontawesome-free'

const application = Application.start()

// From https://janko.io/upgrading-from-selenium-to-cuprite/
if (process.env.RAILS_ENV === 'test') {
  // propagate errors that happen inside Stimulus controllers
  application.handleError = (error, message, detail) => {
    throw error
  }
}

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }

// Note: controllers/index.js must be loaded separately in the HTML to avoid circular dependency
// It will import this application and register all controllers

// Tailwind Plus Elements can be loaded by importing "panda/core/tailwindplus-elements"
// or by adding the script tag directly to your HTML:
// <script src="https://cdn.jsdelivr.net/npm/@tailwindplus/elements@1" type="module"></script>
