import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="prefix-schema"
export default class extends Controller {
  static targets = ["schemaInput", "schemaKey", "customSchemaFields", "schemaViewer", "schemaViewerContent", "schemaEditor", "schemaEditorWrapper", "schemaTypeSelector"]
  static outlets = ["json-editor"]
  static values = {
    schemata: { type: Object, default: {} },
    messages: { type: Object, default: {} },
    initialSelection: { type: String, default: null }
  }

  connect() {
    console.log('PrefixSchemaController connected');

    // Store bound methods for cleanup
    this.boundHandleKeyChange = this.handleSchemaKeyChange.bind(this);
    this.boundInitializeFromTemplate = this.initializeFromTemplate.bind(this);

    // Initialize based on the current selection
    this.initializeFromSelection();

    // Set up event listeners
    if (this.hasSchemaKeyTarget) {
      this.schemaKeyTarget.addEventListener('change', this.boundHandleKeyChange);
    }
  }

  initializeFromSelection() {
    const selection = this.initialSelectionValue;

    if (!selection) {
      console.log('No initial selection, showing selector');
      this.hideAllElements();
      if (this.hasSchemaKeyTarget) {
        this.schemaKeyTarget.style.display = 'block';
      }
      return;
    }

    if (selection === 'custom') {
      // The json-editor controller loads its initial content directly from
      // the hidden field's value (see json_editor_controller.js#connect) -
      // including a graceful fallback if that value isn't valid JSON - so
      // there's nothing further to do here.
      this.showCustomSchemaEditor();
    } else if (this.schemataValue[selection]) {
      this.showSchemaViewer(selection);
    }

    // Update the selector to show the current selection
    if (this.hasSchemaKeyTarget) {
      this.schemaKeyTarget.value = selection;
    }
  }

  showSchemaViewer(schemaKey) {
    this.hideAllElements();

    const schema = this.schemataValue[schemaKey];
    if (schema) {
      // Set the hidden input value to just the schema name
      if (this.hasSchemaInputTarget) {
        this.schemaInputTarget.value = JSON.stringify({ name: schemaKey });
      }

      // Display the schema in the viewer
      if (this.hasSchemaViewerTarget && this.hasSchemaViewerContentTarget) {
        this.schemaViewerContentTarget.textContent = JSON.stringify(schema, null, 2);
        this.schemaViewerTarget.style.display = 'block';
      }

      // Show the selector in case they want to change it
      if (this.hasSchemaKeyTarget) {
        this.schemaKeyTarget.style.display = 'block';
      }
    }
  }

  showCustomSchemaEditor() {
    this.hideAllElements();

    if (this.hasSchemaEditorTarget) {
      this.schemaEditorTarget.style.display = 'block';

      if (this.hasSchemaEditorWrapperTarget) {
        this.schemaEditorWrapperTarget.style.display = 'block';
      }
    }

    // Show the type selector
    if (this.hasSchemaTypeSelectorTarget) {
      this.schemaTypeSelectorTarget.style.display = 'block';
    }

    // Show template selector and custom fields
    const templateSelector = this.element.querySelector('[data-prefix-schema-target="templateSelector"]');
    if (templateSelector) {
      templateSelector.style.display = 'block';
    }

    if (this.hasCustomSchemaFieldsTarget) {
      this.customSchemaFieldsTarget.style.display = 'block';
    }

    // The editor may have mounted while hidden (display:none) - vanilla-jsoneditor
    // can mis-measure its layout in that state, so refresh it now it's visible.
    if (this.hasJsonEditorOutlet) {
      this.jsonEditorOutlet.refresh();
    }
  }

  hideAllElements() {
    console.log('Hiding all elements');
    if (this.hasSchemaViewerTarget) this.schemaViewerTarget.style.display = 'none';
    if (this.hasSchemaEditorTarget) this.schemaEditorTarget.style.display = 'none';
    if (this.hasCustomSchemaFieldsTarget) this.customSchemaFieldsTarget.style.display = 'none';

    // Hide template selector
    const templateSelector = this.element.querySelector('[data-prefix-schema-target="templateSelector"]');
    if (templateSelector) templateSelector.style.display = 'none';

    // Always show the schema key selector
    if (this.hasSchemaKeyTarget) {
      this.schemaKeyTarget.style.display = 'block';
    }
  }

  handleSchemaTypeChange(event) {
    const type = event.target.value;
    if (!type) return;

    try {
      // Initialize a new schema object with the selected type
      const schema = { type };

      // If we have an existing schema, merge it with the new type
      if (this.hasSchemaInputTarget && this.schemaInputTarget.value) {
        try {
          const existingSchema = JSON.parse(this.schemaInputTarget.value);
          if (existingSchema && typeof existingSchema === 'object') {
            Object.assign(schema, existingSchema);
            schema.type = type; // Ensure the new type takes precedence
          }
        } catch (e) {
          console.error('Error parsing existing schema:', e);
          // Continue with just the type if parsing fails
        }
      }

      this.setEditorContent(schema);
    } catch (error) {
      console.error('Error in handleSchemaTypeChange:', error);
    }
  }

  handleSchemaKeyChange(event) {
    const newKey = event.target.value;
    console.log('Schema key changed to:', newKey);

    // Get current key safely
    const currentKey = this.schemaKeyTarget?.dataset?.currentKey ||
                      (this.hasSchemaKeyTarget ? this.schemaKeyTarget.value : '');

    // If changing from custom to a named schema, show confirmation
    if (currentKey === 'custom' && newKey !== 'custom') {
      console.log('Showing confirmation dialog');
      const confirmed = confirm(this.messagesValue?.sure || 'Are you sure you want to change the schema? This will replace your custom schema.');
      if (!confirmed) {
        event.target.value = currentKey;
        return;
      }
    }

    // Update current key
    if (this.schemaKeyTarget) {
      this.schemaKeyTarget.dataset.currentKey = newKey;
    }

    // Handle the new selection
    if (newKey === '') {
      this.hideAllElements();
      if (this.hasSchemaKeyTarget) {
        this.schemaKeyTarget.style.display = 'block';
      }
    } else if (newKey === 'custom') {
      this.showCustomSchemaEditor();

      // Only initialize a default if there's no existing custom schema yet
      if (this.hasSchemaInputTarget && !this.schemaInputTarget.value) {
        const defaultName = this.element.dataset.prefixSchemaDefaultNameValue;
        this.setEditorContent({ name: defaultName });
      }
    } else {
      this.showSchemaViewer(newKey);
    }
  }

  initializeFromTemplate(event) {
    const templateKey = event.target.value;
    if (!templateKey) return;

    console.log('Initializing from template:', templateKey);

    // Only show confirmation if we have existing content to overwrite
    const hasExistingContent = this.hasSchemaInputTarget && this.schemaInputTarget.value?.trim() !== '';

    if (hasExistingContent) {
      const confirmed = confirm(this.messagesValue?.sure || 'Loading a template will replace your current schema. Continue?');
      if (!confirmed) {
        event.target.value = ''; // Reset the template selector to blank
        return;
      }
    }

    try {
      const template = this.schemataValue[templateKey];
      if (template) {
        const schema = {
          ...template,
          name: this.element.dataset.prefixSchemaDefaultNameValue || 'custom'
        };
        this.setEditorContent(schema);
      }
    } catch (e) {
      console.error('Error parsing template schema:', e);
    }

    // Reset the template selector
    event.target.value = '';
  }

  // Writes a schema object into both the submitted hidden field and the
  // visible editor (the two aren't automatically kept in sync in this
  // direction - only user edits in the editor flow back to the hidden field,
  // via json_editor_controller.js's own onChange).
  setEditorContent(schema) {
    if (this.hasSchemaInputTarget) {
      this.schemaInputTarget.value = JSON.stringify(schema);
    }
    if (this.hasJsonEditorOutlet) {
      this.jsonEditorOutlet.setContent(schema);
    }
  }

  // Clean up event listeners
  disconnect() {
    if (this.hasSchemaKeyTarget && this.boundHandleKeyChange) {
      this.schemaKeyTarget.removeEventListener('change', this.boundHandleKeyChange);
    }

    const templateSelector = this.element.querySelector('[data-prefix-schema-target="templateSelector"] select');
    if (templateSelector && this.boundInitializeFromTemplate) {
      templateSelector.removeEventListener('change', this.boundInitializeFromTemplate);
    }
  }
}
