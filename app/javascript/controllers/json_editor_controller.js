import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="json-editor"
// Mounts vanilla-jsoneditor onto containerTarget. Two uses:
// - Editable (see ViewHelper#form_field's :jsonb case): has an inputTarget,
//   the hidden field actually submitted with the form - its value seeds the
//   editor's initial content, and is kept in sync with further edits.
// - Read-only (see ViewHelper#show_attribute's :jsonb case): no inputTarget;
//   initial content instead comes from contentValue, and readOnlyValue
//   disables editing.
// vanilla-jsoneditor is only needed on the few pages that show or edit a
// jsonb column, so it's dynamically imported here rather than loaded on
// every page.
export default class extends Controller {
  static targets = ["container", "input"]
  static values = {
    content: { type: String, default: "" },
    readOnly: { type: Boolean, default: false }
  }

  async connect() {
    const { createJSONEditor } = await import("vanilla-jsoneditor")

    const raw = this.hasInputTarget ? this.inputTarget.value : this.contentValue
    let content
    try {
      content = { json: raw.trim().length > 0 ? JSON.parse(raw) : {} }
    } catch (error) {
      // Already-invalid JSON (e.g. left over from a failed save) - show it as
      // text so the user can see and fix it, rather than discarding it.
      content = { text: raw }
    }

    this.editor = createJSONEditor({
      target: this.containerTarget,
      props: {
        content,
        readOnly: this.readOnlyValue,
        // Lock to tree mode always (edit or read-only) - text/table mode let
        // the user type or paste arbitrary raw text, which is unnecessary
        // surface area for a jsonb column that should only ever hold
        // structured data.
        mode: "tree",
        // Read-only usages (ViewHelper#show_attribute, and the named-schema
        // viewer in disciplines/_prefix_schema_fields) have nothing for a
        // menu bar to do - no editing, and the mode switcher would just let
        // the user flip out of tree mode. Editable usages keep it, both for
        // its own tree-mode controls (search, undo/redo) and because an
        // editor already has full latitude over the field's raw data anyway.
        mainMenuBar: !this.readOnlyValue,
        onChange: this.hasInputTarget
          ? (updatedContent) => {
              this.inputTarget.value = "json" in updatedContent
                ? JSON.stringify(updatedContent.json)
                : updatedContent.text
            }
          : undefined
      }
    })
  }

  disconnect() {
    this.editor?.destroy()
    this.editor = null
  }

  // Public API for other controllers (e.g. via a Stimulus outlet) that need
  // to replace this editor's content programmatically - a plain assignment
  // to inputTarget.value wouldn't update what's actually rendered.
  setContent(json) {
    this.editor?.set({ json })
  }

  // The editor can mount while its container is display:none (e.g. it starts
  // hidden behind a mode selector) and mis-measure its layout as a result -
  // call this after making a previously-hidden editor visible.
  refresh() {
    this.editor?.refresh()
  }
}
