// Initialize Bootstrap components
const initializeBootstrap = () => {
  // Initialize tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTriggerList.map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));

  // Initialize popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
  popoverTriggerList.map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', initializeBootstrap);

// Re-initialize on Turbo navigation
document.addEventListener('turbo:load', initializeBootstrap);
document.addEventListener('turbo:frame-load', initializeBootstrap);
