# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Use local node modules
pin "bootstrap", to: "bootstrap/dist/js/bootstrap.bundle.min.js"
pin "@popperjs/core", to: "@popperjs/core/dist/umd/popper.min.js"
