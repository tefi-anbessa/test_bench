// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import Rails from "@rails/ujs"
Rails.start()

// Initialize Rails UJS for confirm dialogs
window.Rails = Rails

import "controllers"
import 'bootstrap'
// Bootstrap components are already available via the window.bootstrap object
// when using the pre-built bundle

import 'pagy'
// Pagy is already available via the window.Pagy object when using the gem's
// pre-built bundle - Pagy.init() wires up any [data-pagy] element on the page
// (pagy_limit_selector_js, *_nav_js, *_combo_nav_js).

// Import JSONEditor from vendor/javascript
// import { JSONEditor } from 'jsoneditor'
// Make it available globally if needed
// window.JSONEditor = JSONEditor

// Initialize Bootstrap components when the page loads
const initializeBootstrapComponents = () => {
  // Initialize dropdowns
  document.querySelectorAll('.dropdown-toggle').forEach(dropdownToggleEl => {
    new bootstrap.Dropdown(dropdownToggleEl)
  })

  // Initialize tooltips
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(tooltipEl => {
    new bootstrap.Tooltip(tooltipEl)
  })
  
  // Initialize popovers
  document.querySelectorAll('[data-bs-toggle="popover"]').forEach(popoverEl => {
    new bootstrap.Popover(popoverEl)
  })
  
  // Initialize collapsibles with explicit state
  document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(collapseEl => {
    // Skip elements that have Stimulus controllers - they handle their own Bootstrap initialization
    if (collapseEl.hasAttribute('data-controller')) return;

    const target = collapseEl.getAttribute('data-bs-target') || collapseEl.getAttribute('href')
    if (target) {
      const targetEl = document.querySelector(target)
      if (targetEl && !targetEl.hasAttribute('data-bs-collapse-initialized')) {
        new bootstrap.Collapse(targetEl, { toggle: false })
        targetEl.setAttribute('data-bs-collapse-initialized', 'true')
      }
    }
  })
}

// Initialize on page load
document.addEventListener('turbo:load', initializeBootstrapComponents)
document.addEventListener('turbo:render', initializeBootstrapComponents)

// For pages that don't use Turbo
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeBootstrapComponents)
} else {
  initializeBootstrapComponents()
}

// Wire up Pagy's JS-powered nav/selector elements the same way - re-run on
// every Turbo page load/render, since Turbo swaps content without a full reload.
const initializePagy = () => window.Pagy?.init()

document.addEventListener('turbo:load', initializePagy)
document.addEventListener('turbo:render', initializePagy)

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializePagy)
} else {
  initializePagy()
}
