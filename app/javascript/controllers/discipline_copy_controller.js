import { Controller } from "@hotwired/stimulus"

// Pre-fills the rest of the new-discipline form from the standard registry
// when a standard discipline is picked in the "copy from standard" select -
// this is how a discipline excluded when the project was first created gets
// added later. Nothing is applied silently at save time: the user sees
// every copied value and can still edit it before submitting.
//
// The prefix schema's own schema_key select belongs to the separate
// prefix-schema controller's markup (see _prefix_schema_fields.html.erb) -
// rather than reach into that controller directly, this just sets the
// select's value and dispatches a real change event, which the existing
// change->prefix-schema#handleSchemaKeyChange action picks up exactly as if
// a person had chosen it themselves.
export default class extends Controller {
  static values = { registry: Object }
  static targets = ["select", "name", "code", "sortOrder", "requiredRole", "catalogRequiredRole"]

  apply() {
    const entry = this.registryValue[this.selectTarget.value]
    if (!entry) return

    this.nameTarget.value = entry.name
    this.codeTarget.value = this.selectTarget.value
    this.sortOrderTarget.value = entry.sortOrder
    this.requiredRoleTarget.value = entry.requiredRole || ""
    this.catalogRequiredRoleTarget.value = entry.catalogRequiredRole || ""

    const schemaKeySelect = this.element.querySelector("#discipline_schema_key")
    if (schemaKeySelect && entry.prefixSchemaKey) {
      schemaKeySelect.value = entry.prefixSchemaKey
      schemaKeySelect.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }
}
