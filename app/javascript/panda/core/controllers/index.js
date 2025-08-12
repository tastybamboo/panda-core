// Import and register Core Stimulus controllers
import { application } from "../application"

import ThemeFormController from "./theme_form_controller"
application.register("theme-form", ThemeFormController)

// Import and register TailwindCSS Stimulus Components
// These are needed for UI components like slideover, modals, alerts, etc.
import { Alert, Autosave, ColorPreview, Dropdown, Modal, Tabs, Popover, Toggle, Slideover } from "../tailwindcss-stimulus-components"
application.register('alert', Alert)
application.register('autosave', Autosave)
application.register('color-preview', ColorPreview)
application.register('dropdown', Dropdown)
application.register('modal', Modal)
application.register('popover', Popover)
application.register('slideover', Slideover)
application.register('tabs', Tabs)
application.register('toggle', Toggle)

console.debug("[Panda Core] Registered TailwindCSS Stimulus components")