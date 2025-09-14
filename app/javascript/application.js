// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import 'bootstrap'
import { Dropdown } from 'bootstrap'
import { Tooltip } from 'bootstrap'
import { Popover } from 'bootstrap'
// import '@popperjs/core';

// Initialize Bootstrap components when the page loads
document.addEventListener('turbo:load', function() {
  // Initialize dropdowns (they should auto-initialize with data-bs-toggle="dropdown")
  const dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'))
  const dropdownList = dropdownElementList.map(function (dropdownToggleEl) {
    return new Dropdown(dropdownToggleEl)
  })

  // Initialize tooltips
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTriggerList.forEach(function(tooltipTriggerEl) {
    new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Initialize popovers
  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
  popoverTriggerList.forEach(function(popoverTriggerEl) {
    new bootstrap.Popover(popoverTriggerEl);
  });
});
