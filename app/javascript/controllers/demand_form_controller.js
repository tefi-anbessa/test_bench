// app/javascript/controllers/demand_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "basis",
    "power",
    "vector",
    "current",
    "pf",
    "config",
    "supply",
    "supplyReference"
  ]

  static values = {
    supplyOptions: Object
  }

  connect() {
    this.touched = new Set()

    this.basisChanged()
    this.supplyReferenceChanged()

    this.element.addEventListener("demand:recalculate", () => {
      this.recalculate()
    })
  }

  // ---------------------------
  // Voltage switching
  // ---------------------------
  supplyReferenceChanged() {
    const ref = this.supplyReferenceTarget.value

    let options = {}

    if (ref === "ln") {
      options = this.supplyOptionsValue.line_to_neutral
    } else if (ref === "ll") {
      options = this.supplyOptionsValue.line_to_line
    }

    // 🔥 Broadcast to typed-select (decoupled)
    this.element.dispatchEvent(
      new CustomEvent("typed-select:set-options", {
        detail: { options: options },
        bubbles: true
      })
    )
  }

  // ---------------------------
  // Basis behaviour
  // ---------------------------
  basisChanged() {
    const basis = this.basisTarget.value

    this.disableAll()

    switch (basis) {
      case "power_pf":
        this.enable(this.powerTarget, this.pfTarget)
        break

      case "vector_pf":
        this.enable(this.vectorTarget, this.pfTarget)
        break

      case "current_pf":
        this.enable(this.currentTarget, this.pfTarget)
        break

      case "current_power":
        this.enable(this.currentTarget, this.powerTarget)
        break
    }
  }

  // ---------------------------
  // Input handling
  // ---------------------------
  inputChanged(event) {
    if (event) this.touched.add(event.target.name)

    if (!this.readyToCalculate()) return

    this.recalculate()
  }

  supplyChanged(event) {
    this.supplyTarget.value = event.detail.value

    this.touched.add("supply")

    if (!this.readyToCalculate()) return

    this.recalculate()
  }

  readyToCalculate() {
    return (
      this.configTarget.value &&
      this.supplyTarget.value &&
      this.activeInputsFilled()
    )
  }

  activeInputsFilled() {
    const basis = this.basisTarget.value

    switch (basis) {
      case "power_pf":
        return this.powerTarget.value && this.pfTarget.value

      case "vector_pf":
        return this.vectorTarget.value && this.pfTarget.value

      case "current_pf":
        return this.currentTarget.value && this.pfTarget.value

      case "current_power":
        return this.currentTarget.value && this.powerTarget.value

      default:
        return false
    }
  }

  recalculate() {
    // No maths here — server should handle it
    this.element.dispatchEvent(
      new CustomEvent("demand:recalculate", { bubbles: true })
    )
  }

  // ---------------------------
  // Helpers
  // ---------------------------
  disableAll() {
    [this.powerTarget, this.vectorTarget, this.currentTarget]
      .forEach(el => el.disabled = true)
  }

  enable(...els) {
    els.forEach(el => el.disabled = false)
  }

  recalculate() {
    const form = this.element.closest("form")

    if (!form) return

    const url = form.dataset.recalculateUrl

    const formData = new FormData(form)

    fetch(url, {
      method: "POST",
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    })
  }
}