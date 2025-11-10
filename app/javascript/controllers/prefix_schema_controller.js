
import { Controller } from "@hotwired/stimulus"
// Import JSONEditor as a module
import JSONEditor from "jsoneditor"

export default class extends Controller {
  static targets = ["editorContainer", "schemaInput", "schemaKey", "customSchemaFields"]
  static values = { 
    schemata: { type: Object, default: {} },
    messages: { type: Object, default: {} }
}

  connect() {
    this.initializeEditor()
    this.toggleSchemaKey()
    // Remove any existing listeners to prevent duplicates
    this.schemaKeyTarget.removeEventListener('change', this.boundHandleKeyChange)
    this.boundHandleKeyChange = this.handleSchemaKeyChange.bind(this)
    this.schemaKeyTarget.addEventListener('change', this.boundHandleKeyChange)
  }
  

  initializeEditor() {
    this.editor = new JSONEditor(this.editorContainerTarget, {
      mode: 'tree',
      modes: ['tree', 'view'],
      onError: (err) => {
        console.error('JSON Editor Error:', err)
      }
    })
  }

  async handleSchemaKeyChange(event) {
    const newKey = event.target.value
    
    if (newKey === '') {
      // Clear the schema if selecting blank
      this.schemaInputTarget.value = ''
      this.editorContainerTarget.style.display = 'none'
      return
    }

    if (newKey !== 'custom' && this.schemaInputTarget.value) {
      const confirmed = confirm(this.messagesValue.sure || 'Are you sure?')
      if (!confirmed) {
      console.log('User cancelled')
        event.target.value = this.schemaInputTarget.dataset.currentKey || ''
        return
      }
    }

    // Update current key
  console.log('Updating to new key:', newKey)
    this.schemaInputTarget.dataset.currentKey = newKey

    if (newKey === 'custom') {
    console.log('Showing custom schema editor')
      this.showCustomSchemaEditor()
    } else if (newKey === 'default') {
    console.log('Clearing schema')
      this.schemaInputTarget.value = ''
      this.editorContainerTarget.style.display = 'none'
      this.customSchemaFieldsTarget.style.display = 'none' 
    } else {
    console.log('Loading schema for key:', newKey)
      await this.showReadOnlySchema(newKey)
    }
  }

  showCustomSchemaEditor() {
    console.log('showCustomSchemaEditor called')
    this.editorContainerTarget.style.display = 'block'
    this.customSchemaFieldsTarget.style.display = 'block' // Make sure this is shown
    this.editor.setMode('tree')
    this.editor.options.onEditable = () => true
    this.editor.refresh()
  }

  async showReadOnlySchema(schemaKey) {
  console.log('showReadOnlySchema called with key:', schemaKey)
  console.log('Available schemata:', Object.keys(this.schemataValue))
    this.editorContainerTarget.style.display = 'block'
    this.editor.setMode('view')
    
    try {
      const schema = this.schemataValue[schemaKey]
    console.log('Found schema:', schema)
      this.editor.set(schema)
      this.schemaInputTarget.value = JSON.stringify(schema)
    } catch (error) {
      console.error('Error loading schema:', error)
    }
  }

  initializeFromTemplate(event) {
    const templateKey = event.target.value
    if (!templateKey) return

      try {
    console.log('Initializing from template:', templateKey)
        const schema = this.schemataValue[templateKey]
        console.log('Found schema:', schema)
        if (schema) {
          this.editor.set(schema)
          this.schemaInputTarget.value = JSON.stringify(schema)
        } else {
          console.error('Schema not found for key:', templateKey)
        }
      } catch (error) {
        console.error('Error in showReadOnlySchema:', error)
      }
  }

  toggleSchemaKey() {
    const isCustom = this.element.querySelector('input[type="radio"][value="custom"]:checked') !== null
    this.schemaKeyTarget.style.display = isCustom ? 'none' : 'block'
    this.customSchemaFieldsTarget.style.display = isCustom ? 'block' : 'none'
  }

  // Clean up
  disconnect() {
    if (this.editor) {
      this.editor.destroy()
    }
    this.schemaKeyTarget.removeEventListener('change', this.handleSchemaKeyChange)
  }
}