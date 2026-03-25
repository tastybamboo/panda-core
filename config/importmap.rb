# frozen_string_literal: true

# Panda Core application and controllers
# Served via Rack::Static middleware from app/javascript
pin "panda/core/application", to: "/panda/core/application.js"
pin "panda/core/controllers/index", to: "/panda/core/controllers/index.js"
pin "panda/core/controllers/toggle_controller", to: "/panda/core/controllers/toggle_controller.js"
pin "panda/core/controllers/theme_form_controller", to: "/panda/core/controllers/theme_form_controller.js"
pin "panda/core/controllers/image_cropper_controller", to: "/panda/core/controllers/image_cropper_controller.js"
pin "panda/core/tailwindplus-elements", to: "/panda/core/tailwindplus-elements.js"

# Base JavaScript dependencies for Panda Core (all vendored for reliability)
pin "@hotwired/stimulus", to: "/panda/core/vendor/@hotwired--stimulus.js", preload: true # @3.2.2
pin "@hotwired/turbo", to: "/panda/core/vendor/@hotwired--turbo.js", preload: true # @8.0.23
pin "@rails/actioncable/src", to: "/panda/core/vendor/@rails--actioncable--src.js", preload: true # @8.1.300
pin "tailwindcss-stimulus-components", to: "/panda/core/tailwindcss-stimulus-components.js" # @6.1.3

# Font Awesome icons (vendored)
pin "@fortawesome/fontawesome-free", to: "/panda/core/vendor/@fortawesome--fontawesome-free@7.2.0.js" # @7.2.0

# Tailwind Plus Elements - Vanilla JS interactive components (vendored)
# Provides: Autocomplete, Command palette, Dialog, Disclosure, Dropdown menu, Popover, Select, Tabs
pin "@tailwindplus/elements", to: "/panda/core/vendor/@tailwindplus--elements@1.0.22.js", preload: false # @1.0.22

# Cropper.js - Image cropping library (vendored)
# Note: v2.x uses Web Components — no separate CSS file needed
pin "cropperjs", to: "/panda/core/vendor/cropperjs@2.1.0.js" # @2.1.0

# Vanilla Calendar Pro - Date picker library (vendored)
pin "vanilla-calendar-pro", to: "/panda/core/vendor/vanilla-calendar-pro.js" # @3.1.0
