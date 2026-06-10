// controllers/typed_select_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    options: Array,
    type: { type: String, default: "string" } // "number" or "string"
  }

  connect() {
    this.build()
    this.bindEvents()
  }

  build() {
    this.wrapper = document.createElement("div")
    this.wrapper.classList.add("dropdown")

    this.menu = document.createElement("div")
    this.menu.classList.add("dropdown-menu")

    this.element.parentNode.insertBefore(this.wrapper, this.element)
    this.wrapper.appendChild(this.element)
    this.wrapper.appendChild(this.menu)

    this.renderOptions(this.optionsValue)
  }

  bindEvents() {
    this.element.addEventListener("focus", () => this.show())
    this.element.addEventListener("input", () => this.filter())
    document.addEventListener("click", (e) => {
      if (!this.wrapper.contains(e.target)) this.hide()
    })
  }

  renderOptions(options) {
    this.menu.innerHTML = ""

    options.forEach(opt => {
      const option = this.normalize(opt)

      const item = document.createElement("button")
      item.type = "button"
      item.classList.add("dropdown-item")
      item.textContent = option.label

      item.addEventListener("click", () => {
        this.select(option)
      })

      this.menu.appendChild(item)
    })
  }

  filter() {
    const term = this.element.value.toLowerCase()

    const filtered = this.optionsValue.filter(opt => {
      const o = this.normalize(opt)
      return o.label.toLowerCase().includes(term)
    })

    this.renderOptions(filtered)
    this.show()
  }
  
  select(option) {
    let value = option.value

    if (this.typeValue === "number") {
      value = parseFloat(value)
    }

    this.element.value = value
    this.element.dispatchEvent(new Event("input"))
    this.hide()
  }

  normalize(opt) {
    if (typeof opt === "object") return opt
    return { value: opt, label: String(opt) }
  }

  show() {
    this.menu.classList.add("show")
  }

  hide() {
    this.menu.classList.remove("show")
  }
}