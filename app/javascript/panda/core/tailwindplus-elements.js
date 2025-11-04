/**
 * Tailwind Plus Elements Loader
 *
 * This module loads the Tailwind Plus Elements library for vanilla JS interactive components.
 * It provides eight foundational primitives:
 * - Autocomplete: enables custom combobox implementations
 * - Command palette: builds searchable command interfaces
 * - Dialog: creates modals, drawers, and overlays
 * - Disclosure: handles collapsible sections and mobile menus
 * - Dropdown menu: constructs option menus
 * - Popover: manages floating UI elements
 * - Select: builds custom dropdown selects
 * - Tabs: creates tabbed interfaces
 *
 * Usage:
 *   import "@tailwindplus/elements"
 *
 * Or lazy-load when needed:
 *   import("@tailwindplus/elements").then(() => {
 *     // Elements are now available
 *   })
 *
 * Documentation: https://tailwindcss.com/blog/vanilla-js-support-for-tailwind-plus
 */

// Auto-import Tailwind Plus Elements
// This makes custom elements like <el-dropdown>, <el-dialog>, etc. available
import "@tailwindplus/elements"

// Export for module consumers
export default "@tailwindplus/elements"
