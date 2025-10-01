import { Controller } from "@hotwired/stimulus"

// Simple debounce helper
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func.apply(this, args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

export default class extends Controller {
  static targets = ["preview"]
  static values = { 
    defaultText: { type: String, default: 'Tag' },
    modelName: { type: String, default: 'Tag' }
  }

  connect() {
    console.log('Tag controller connected', this.element);
    
    // Debounce the updatePreview method to avoid too many updates
    this.debouncedUpdatePreview = debounce(this.updatePreview.bind(this), 100);
    
    // Set up event listeners
    this.setupEventListeners();
    
    // Initial update
    this.updatePreview();
    
    // For debugging
    window.tagController = this;
  }
  
  disconnect() {
    this.teardownEventListeners();
  }
  
  setupEventListeners() {
    // Listen for input events on the form
    this.boundUpdateHandler = this.handleFormUpdate.bind(this);
    document.addEventListener('input', this.boundUpdateHandler);
    document.addEventListener('change', this.boundUpdateHandler);
  }
  
  teardownEventListeners() {
    document.removeEventListener('input', this.boundUpdateHandler);
    document.removeEventListener('change', this.boundUpdateHandler);
  }
  
  handleFormUpdate(event) {
    // Only process if the event came from one of our form fields
    const target = event.target;
    if (target.matches('[name*="[prefix]"], [name*="[serial]"], [name*="[suffix]"]')) {
      this.debouncedUpdatePreview();
    }
  }

  updatePreview() {
    try {
      // Get the form that's a parent of this controller
      const form = this.element.closest('form') || document.querySelector('form');
      if (!form) {
        console.error('No form found');
        return;
      }
      
      // Get field values using form elements
      const prefix = form.elements['tag[prefix]']?.value || '';
      const serial = (form.elements['tag[serial]']?.value || '').padStart(4, '0');
      const suffix = form.elements['tag[suffix]']?.value || '';
      
      // Build the full tag
      const fullTag = [prefix, serial, suffix].filter(Boolean).join('');
      
      // Update the preview if we have a target
      if (this.hasPreviewTarget) {
        const previewText = fullTag 
          ? `${this.modelNameValue}: ${fullTag}`
          : this.defaultTextValue;
        
        this.previewTarget.textContent = previewText;
      }
      
    } catch (error) {
      console.error('Error in updatePreview:', error);
    }
  }
}
