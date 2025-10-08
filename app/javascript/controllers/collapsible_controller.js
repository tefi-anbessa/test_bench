import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    // Set initial state
    const targetId = this.element.getAttribute('data-bs-target') || 
                    this.element.getAttribute('href')
    this.collapseElement = targetId ? document.querySelector(targetId) : null
    
    if (this.collapseElement) {
      // Listen for Bootstrap collapse events to update icon when state actually changes
      this.collapseElement.addEventListener('shown.bs.collapse', this.updateIcon.bind(this))
      this.collapseElement.addEventListener('hidden.bs.collapse', this.updateIcon.bind(this))
    }
    
    // Add click handler
    this.element.addEventListener('click', this.toggle.bind(this))
    
    // Update icon based on initial state
    this.updateIcon()
  }

  disconnect() {
    if (this.collapseElement) {
      this.collapseElement.removeEventListener('shown.bs.collapse', this.updateIcon.bind(this))
      this.collapseElement.removeEventListener('hidden.bs.collapse', this.updateIcon.bind(this))
    }
    this.element.removeEventListener('click', this.toggle)
  }

  toggle(event) {
    // Only handle if this is the actual click target (not a child element)
    if (event.target === this.element || this.element.contains(event.target)) {
      if (this.collapseElement) {
        const bsCollapse = bootstrap.Collapse.getInstance(this.collapseElement) || 
                         new bootstrap.Collapse(this.collapseElement, { toggle: true })
      }
      this.updateIcon()
    }
  }
  
  updateIcon() {
    if (this.hasIconTarget) {
      const isExpanded = this.collapseElement && this.collapseElement.classList.contains('show')
      // Remove all rotation classes first
      this.iconTarget.classList.remove('collapsed', 'expanded')
      // Add the appropriate class based on state
      this.iconTarget.classList.add(isExpanded ? 'expanded' : 'collapsed')
    }
  }
}