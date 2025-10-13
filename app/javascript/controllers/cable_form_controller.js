// app/javascript/controllers/cable_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fromType", "fromId", "toType", "toId"]
  
static values = {
  idOptions: Object  // Changed from fromOptions and toOptions
}

updateFromOptions() {
  const selectedType = this.fromTypeTarget.value
  const options = this.idOptionsValue[selectedType] || []  // Changed from fromOptionsValue
  this.updateSelectOptions(this.fromIdTarget, options)
}

updateToOptions() {
  const selectedType = this.toTypeTarget.value  
  const options = this.idOptionsValue[selectedType] || []  // Changed from toOptionsValue
  this.updateSelectOptions(this.toIdTarget, options)
}

  updateSelectOptions(select, options) {
    // Clear existing options
    select.innerHTML = '<option value=""></option>'
    
    // Add new options
    options.forEach(([text, value]) => {
      const option = document.createElement('option')
      option.value = value
      option.textContent = text
      select.appendChild(option)
    })
  }
}