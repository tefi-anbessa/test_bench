// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import 'bootstrap'
import { Dropdown, Tooltip, Popover, Collapse } from 'bootstrap'
window.bootstrap = { Dropdown, Tooltip, Popover, Collapse }

// Initialize Bootstrap components when the page loads
const initializeBootstrapComponents = () => {
  // Initialize dropdowns
  document.querySelectorAll('.dropdown-toggle').forEach(dropdownToggleEl => {
    new Dropdown(dropdownToggleEl)
  })

  // Initialize tooltips
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(tooltipEl => {
    new Tooltip(tooltipEl)
  })
  
  // Initialize popovers
  document.querySelectorAll('[data-bs-toggle="popover"]').forEach(popoverEl => {
    new Popover(popoverEl)
  })
  
  // Initialize collapsibles with explicit state
  document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(collapseEl => {
    const target = collapseEl.getAttribute('data-bs-target') || collapseEl.getAttribute('href')
    if (target) {
      const targetEl = document.querySelector(target)
      if (targetEl && !targetEl.hasAttribute('data-bs-collapse-initialized')) {
        new Collapse(targetEl, { toggle: false })
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
