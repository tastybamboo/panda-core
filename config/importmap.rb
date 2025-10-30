# frozen_string_literal: true

# Panda Core application and controllers
pin "panda/core/application", to: "panda/core/application.js"
pin "panda/core/controllers/index", to: "panda/core/controllers/index.js"
pin_all_from Panda::Core::Engine.root.join("app/javascript/panda/core/controllers"), under: "panda/core/controllers"

# Base JavaScript dependencies for Panda Core (vendored for reliability)
pin "@hotwired/stimulus", to: "panda/core/vendor/@hotwired--stimulus.js", preload: true # @3.2.2
pin "@hotwired/turbo", to: "panda/core/vendor/@hotwired--turbo.js", preload: true # @8.0.18
pin "@rails/actioncable/src", to: "panda/core/vendor/@rails--actioncable--src.js", preload: true # @8.0.201
pin "tailwindcss-stimulus-components", to: "panda/core/tailwindcss-stimulus-components.js" # @6.1.3

# Font Awesome icons (from CDN)
pin "@fortawesome/fontawesome-free", to: "https://ga.jspm.io/npm:@fortawesome/fontawesome-free@7.1.0/js/all.js"
