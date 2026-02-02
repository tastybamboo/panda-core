// Import and register Core Stimulus controllers
import { application } from "../application.js"

import ThemeFormController from "./theme_form_controller.js"
application.register("theme-form", ThemeFormController)

import ImageCropperController from "./image_cropper_controller.js"
application.register("image-cropper", ImageCropperController)

import NavigationToggleController from "./navigation_toggle_controller.js"
application.register("navigation-toggle", NavigationToggleController)

import RowLinkController from "./row_link_controller.js"
application.register("row-link", RowLinkController)

import CollapsibleItemController from "./collapsible_item_controller.js"
application.register("collapsible-item", CollapsibleItemController)

import CustomSelectController from "./custom_select_controller.js"
application.register("custom-select", CustomSelectController)

// Import and register TailwindCSS Stimulus Components
// These are needed for UI components like slideover, modals, alerts, etc.
import { Alert, Autosave, ColorPreview, Dropdown, Modal, Tabs, Popover, Toggle, Slideover } from "../tailwindcss-stimulus-components.js"
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