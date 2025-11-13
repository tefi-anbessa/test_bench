# Pin npm packages by running ./bin/importmap

# Core Rails and Hotwire
pin "application", preload: true

pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.1.3/app/assets/javascripts/rails-ujs.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# JSONEditor - used only in specific views
# pin "jsoneditor", to: "jsoneditor/dist/jsoneditor.min.js"
# Bootstrap and dependencies
pin "bootstrap", to: "bootstrap/js/bootstrap.bundle.min.js" # @5.3.8
# pin "popper", to: "@popperjs/core/dist/esm/popper.js" # @2.11.8
pin "@popperjs/core", to: "@popperjs/core/lib/index.js"

# vanilla-jseditor and a few dependencies...
