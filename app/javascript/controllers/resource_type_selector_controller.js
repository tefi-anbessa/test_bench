import { Controller } from "@hotwired/stimulus"

// Repopulates the role[name] select when the role[resource_type] select
// changes. roleNamesValue is pre-filtered server-side (RolesHelper#role_names_by_resource_type)
// to only the roles the current user may actually grant, keyed by raw
// resource_type ("" for global), so no request is needed here.
export default class extends Controller {
  static targets = ["roleSelect"]
  static values = { roleNames: Object }

  updateResourceSelect(event) {
    if (!this.hasRoleSelectTarget) return

    const options = this.roleNamesValue[event.target.value] || []
    const previousValue = this.roleSelectTarget.value

    this.roleSelectTarget.innerHTML = ""
    this.roleSelectTarget.appendChild(this.buildOption("", ""))
    options.forEach(([label, value]) => {
      this.roleSelectTarget.appendChild(this.buildOption(label, value))
    })

    if (options.some(([, value]) => value === previousValue)) {
      this.roleSelectTarget.value = previousValue
    }
  }

  buildOption(label, value) {
    const option = document.createElement("option")
    option.value = value
    option.textContent = label
    return option
  }
}
