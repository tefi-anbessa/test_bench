import { Controller } from "@hotwired/stimulus"

// Handles combining two IP rating digits into a single field
//
// Usage:
// <div data-controller="ip-rating">
//   <select data-ip-rating-target="firstDigit" data-action="change->ip-rating#update">
//   <select data-ip-rating-target="secondDigit" data-action="change->ip-rating#update">
//   <input type="text" data-ip-rating-target="output" readonly>
// </div>
//
// The output field will be updated whenever either select changes

export default class extends Controller {
  static targets = ["firstDigit", "secondDigit", "output"]

  connect() {
    this.update()
  }

  update() {
    if (!this.hasFirstDigitTarget || !this.hasSecondDigitTarget || !this.hasOutputTarget) return
    
    const first = this.firstDigitTarget.value || ''
    const second = this.secondDigitTarget.value || ''
    this.outputTarget.value = `${first}${second}`
  }
}
