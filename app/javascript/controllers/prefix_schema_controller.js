import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="prefix-schema"
export default class extends Controller {
  static targets = ["schemaInput", "schemaKey", "customSchemaFields", "schemaViewer", "schemaViewerContent", "schemaEditor", "schemaEditorWrapper", "schemaTypeSelector"]
  static values = { 
    schemata: { type: Object, default: {} },
    messages: { type: Object, default: {} },
    initialSelection: { type: String, default: null },
    initialSchema: { type: String, default: null }
  }
  
  connect() {
    console.log('PrefixSchemaController connected');
    
    // Store bound methods for cleanup
    this.boundHandleKeyChange = this.handleSchemaKeyChange.bind(this);
    this.boundInitializeFromTemplate = this.initializeFromTemplate.bind(this);
    this.boundUpdateSchemaInput = this.updateSchemaInput.bind(this);
    
    // Initialize based on the current selection
    this.initializeFromSelection();
    
    // Set up event listeners
    if (this.hasSchemaKeyTarget) {
      this.schemaKeyTarget.addEventListener('change', this.boundHandleKeyChange);
    }
    
    // Add input listener for the schema editor
    if (this.hasSchemaEditorTarget) {
      this.schemaEditorTarget.addEventListener('input', this.boundUpdateSchemaInput);
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
      this.showCustomSchemaEditor();
      if (this.initialSchemaValue) {
        // Note: This is only for display formatting, not validation
        // Model validation will handle any invalid data on form submission
        try {
          // Parse and re-stringify with pretty print for display
          const schema = JSON.parse(this.initialSchemaValue);
          this.schemaEditorTarget.value = JSON.stringify(schema, null, 2);
          // Also update the hidden input with the original value
          // (the model will validate this on submission)
          if (this.hasSchemaInputTarget) {
            this.schemaInputTarget.value = this.initialSchemaValue;
          }
        } catch (e) {
          // If we can't parse the JSON, still show it as-is
          // The model's validation will catch any issues on submission
          console.debug('Could not parse schema for pretty printing, showing as-is');
          this.schemaEditorTarget.value = this.initialSchemaValue;
        }
      }
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
    
    // Show the editor and template selector
    if (this.hasSchemaEditorTarget) {
      // If the field is required, ensure it's visible
      if (this.schemaEditorTarget.required) {
        this.schemaEditorTarget.style.display = 'block';
      } else {
        this.schemaEditorTarget.style.display = 'block';
      }
      
      // Ensure the wrapper is visible
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
      
      // If we have an existing schema in the editor, merge it with the new type
      if (this.hasSchemaEditorTarget && this.schemaEditorTarget.value) {
        try {
          const existingSchema = JSON.parse(this.schemaEditorTarget.value);
          if (existingSchema && typeof existingSchema === 'object') {
            Object.assign(schema, existingSchema);
            schema.type = type; // Ensure the new type takes precedence
          }
        } catch (e) {
          console.error('Error parsing existing schema:', e);
          // Continue with just the type if parsing fails
        }
      }
      
      // Update the editor with the modified schema
      if (this.hasSchemaEditorTarget) {
        this.schemaEditorTarget.value = JSON.stringify(schema, null, 2);
      }
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
      
      // Only initialize default if the editor is empty
      if (this.hasSchemaEditorTarget && !this.schemaEditorTarget.value) {
        const defaultName = this.element.dataset.prefixSchemaDefaultNameValue;
        this.schemaInputTarget.value = JSON.stringify({ name: defaultName });
      } else if (this.hasSchemaEditorTarget) {
        // Update hidden input with current editor content
        this.updateSchemaInput();
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
    const hasExistingContent = this.schemaEditorTarget?.value?.trim() !== '';
    
    if (hasExistingContent) {
      const confirmed = confirm(this.messagesValue?.sure || 'Loading a template will replace your current schema. Continue?');
      if (!confirmed) {
        event.target.value = ''; // Reset the template selector to blank
        return;
      }
    }
    
    try {
      const template = this.schemataValue[templateKey];
      if (template && this.hasSchemaEditorTarget) {
        const schema = { 
          ...template,
          name: this.element.dataset.prefixSchemaDefaultNameValue || 'custom'
        };
        const schemaString = JSON.stringify(schema, null, 2);
        this.schemaEditorTarget.value = schemaString;
        this.schemaInputTarget.value = schemaString;
      }
    } catch (e) {
      console.error('Error parsing template schema:', e);
    }
    
    // Reset the template selector
    event.target.value = '';
  }
  
  updateSchemaInput() {
    if (this.hasSchemaEditorTarget && this.hasSchemaInputTarget) {
      try {
        // Only update if we have valid JSON
        const value = this.schemaEditorTarget.value.trim();
        if (value) {
          const parsed = JSON.parse(value);
          this.schemaInputTarget.value = JSON.stringify(parsed);
        } else {
          this.schemaInputTarget.value = '';
        }
      } catch (e) {
        // If invalid JSON, don't update the hidden field
        console.error('Invalid JSON in schema editor');
      }
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
    
    if (this.hasSchemaEditorTarget && this.boundUpdateSchemaInput) {
      this.schemaEditorTarget.removeEventListener('input', this.boundUpdateSchemaInput);
    }
  }
}