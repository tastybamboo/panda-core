pin "@hotwired/turbo-rails", to: "turbo.js"
pin "@hotwired/stimulus", to: "stimulus.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Panda Core JS (engine)
pin_all_from Panda::Core::Engine.root.join("app/javascript/panda/core"), under: "panda/core"
