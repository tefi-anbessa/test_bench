import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="numeric-mask"
export default class extends Controller {
  static targets = ["input"]
  static values = { digits: { type: Number, default: 4 } }

  connect() {
    this.formatValue()
    
    // Add event listeners
    this.inputTarget.addEventListener('input', this.formatValue.bind(this))
    this.inputTarget.addEventListener('blur', this.formatValue.bind(this))
  }

  disconnect() {
    // Clean up event listeners
    this.inputTarget.removeEventListener('input', this.formatValue.bind(this))
    this.inputTarget.removeEventListener('blur', this.formatValue.bind(this))
  }

  formatValue() {
    // Get the current value and remove non-numeric characters
    let value = this.inputTarget.value.replace(/\D/g, '')
    
    // Pad with leading zeros
    value = value.padStart(this.digitsValue, '0')
    
    // Update the input value
    if (this.inputTarget.value !== value) {
      this.inputTarget.value = value
    }
    
    // Trigger change event to update any dependent fields
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }
}
