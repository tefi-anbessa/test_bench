import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="json-editor"
// Mounts vanilla-jsoneditor onto containerTarget, keeping inputTarget (the
// hidden field actually submitted with the form) in sync with its content.
// vanilla-jsoneditor is only needed on the few forms that edit a jsonb
// column, so it's dynamically imported here rather than loaded on every page.
export default class extends Controller {
  static targets = ["container", "input"]

  async connect() {
    const { createJSONEditor } = await import("vanilla-jsoneditor")

    const raw = this.inputTarget.value
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
        onChange: (updatedContent) => {
          this.inputTarget.value = "json" in updatedContent
            ? JSON.stringify(updatedContent.json)
            : updatedContent.text
        }
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
