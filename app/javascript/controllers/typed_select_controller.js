// app/javascript/controllers/typed_select_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "menu"]

  connect() {
    this.options = {}

    // Listen for external updates (decoupled)
    this.element.addEventListener("typed-select:set-options", (e) => {
      this.setOptions(e.detail.options)
    })
  }

  // ---------------------------
  // Public API
  // ---------------------------
  setOptions(options) {
    this.options = options || {}

    // Only clear if current value is invalid
    const current = parseFloat(this.hiddenTarget.value)

    if (!Object.values(this.options).includes(current)) {
      this.clear()
    }
  }

  // ---------------------------
  // UI behaviour
  // ---------------------------
  search() {
    const term = this.inputTarget.value.toLowerCase()

    const results = Object.entries(this.options)
      .filter(([label]) => label.toLowerCase().includes(term))

    this.render(results)
  }

  render(items) {
    this.menuTarget.innerHTML = ""

    items.forEach(([label, value]) => {
      const el = document.createElement("button")
      el.type = "button"
      el.classList.add("dropdown-item")
      el.textContent = label

      el.addEventListener("click", () => {
        this.select(label, value)
      })

      this.menuTarget.appendChild(el)
    })

    this.menuTarget.classList.toggle("show", items.length > 0)
  }

  select(label, value) {
    this.inputTarget.value = label
    this.hiddenTarget.value = value
    this.menuTarget.classList.remove("show")

    // 🔥 Notify others (this is key)
    this.dispatch("changed", {
      detail: { value: value }
    })
  }

  commit() {
    // Allow manual numeric entry
    if (!this.hiddenTarget.value) {
      const val = parseFloat(this.inputTarget.value)

      if (!isNaN(val)) {
        this.hiddenTarget.value = val

        this.dispatch("changed", {
          detail: { value: val }
        })
      }
    }
  }

  clear() {
    this.inputTarget.value = ""
    this.hiddenTarget.value = ""
    this.menuTarget.innerHTML = ""
  }
}