// Manages the page size selection form
// Submits the form when the page size is changed
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Submit the form when the page size is changed
  submit(event) {
    // Prevent default form submission if we're handling it programmatically
    if (event) {
      event.preventDefault()
    }
    
    // Submit the form
    this.element.requestSubmit()
  }
}
