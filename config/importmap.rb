# Pin npm packages by running ./bin/importmap

# Core Rails and Hotwire
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.1.3/app/assets/javascripts/rails-ujs.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap and dependencies
pin "bootstrap", to: "bootstrap/dist/js/bootstrap.esm.js"
pin "@popperjs/core", to: "@popperjs/core/lib/index.js"

pin "jsoneditor", to: "jsoneditor/dist/jsoneditor.min.js" # in vendor/javascript