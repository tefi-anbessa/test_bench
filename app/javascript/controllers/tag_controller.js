import { Controller } from "@hotwired/stimulus"

// Simple debounce helper
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func.apply(this, args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

export default class extends Controller {
  static targets = ["preview", "discipline", "prefixContainer"]
  static values = {
    defaultText: { type: String, default: 'Tag' },
    modelName: { type: String, default: 'Tag' }
  }

  connect() {
    console.log('Tag controller connected', this.element);

    // Debounce the updatePreview method to avoid too many updates
    this.debouncedUpdatePreview = debounce(this.updatePreview.bind(this), 100);

    // Set up event listeners
    this.setupEventListeners();

    // Initial setup - check if discipline is already selected and update form structure
    const initialDiscipline = this.element.querySelector('[name="tag[discipline_id]"]')?.value ||
                            this.element.querySelector('[name*="[discipline_id]"]')?.value;
    if (initialDiscipline) {
      console.log('Initial discipline found:', initialDiscipline);
      this.updateFormStructure();
    } else {
      console.log('No initial discipline found');
    }

    // For debugging
    window.tagController = this;
  }

  disconnect() {
    this.teardownEventListeners();
  }

  setupEventListeners() {
    // Listen for input events on the form
    this.boundUpdateHandler = this.handleFormUpdate.bind(this);
    this.element.addEventListener('input', this.boundUpdateHandler);
    this.element.addEventListener('change', this.boundUpdateHandler);
  }

  teardownEventListeners() {
    this.element.removeEventListener('input', this.boundUpdateHandler);
    this.element.removeEventListener('change', this.boundUpdateHandler);
  }

  handleFormUpdate(event) {
    const target = event.target;

    // Handle discipline changes
    if (target.matches('[name*="[discipline_id]"]')) {
      this.updateFormStructure();
    }

    // Handle prefix field updates (any of the new dynamic fields)
    if (target.matches('[name*="[prefix]"], [name*="[serial]"], [name*="[suffix]"], [name*="[measured_variable]"], [name*="[modifier]"], [name*="[function]"], [name*="[modifier_function]"]')) {
      this.debouncedUpdatePreview();
    }
  }

  async updateFormStructure() {
    // Try multiple selectors to find the discipline field
    const disciplineSelect = this.element.querySelector('[name="tag[discipline_id]"]') ||
                           this.element.querySelector('[name*="[discipline_id]"]') ||
                           this.element.querySelector('select[name*="discipline"]');
    if (!disciplineSelect) return;

    const disciplineId = disciplineSelect.value;
    if (!disciplineId) return;

    try {
      // Fetch schema data for this discipline
      const response = await fetch(`/tags/schema_data?discipline_id=${disciplineId}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
        },
        credentials: 'same-origin'
      });

      if (response.ok) {
        const schemaData = await response.json();
        this.renderFormFields(schemaData);
      }
    } catch (error) {
      console.error('Error fetching schema data:', error);
    }
  }
  renderFormFields(schemaData) {
    // Find the container for prefix fields within the form
    const prefixContainer = this.element.querySelector('[data-tag-prefix-container]');
    if (!prefixContainer) return;

    // Get current values from data attributes
    const currentPrefix = prefixContainer.dataset.currentPrefix || '';
    const prefixParts = JSON.parse(prefixContainer.dataset.prefixParts || '{}');
    const disciplineId = prefixContainer.dataset.disciplineId || '';
    const hasSchema = prefixContainer.dataset.hasSchema === 'true';

    let fieldsHtml = '';

    if (schemaData.prefix_schema === 'dim1' || schemaData.prefixes) {
      // :dim1 schema - simple prefix selection
      fieldsHtml = `
        <div class="form-group row mb-1">
          <label class="col-form-label col-sm-4" for="tag_prefix">Prefix</label>
          <div class="col-sm-8">
            <select name="tag[prefix]" class="form-select" id="tag_prefix" data-action="change->tag#updatePreview">
              <option value="">Select Prefix</option>
              ${(schemaData.prefixes || []).map(([value, label]) =>
                `<option value="${value}" ${value === currentPrefix ? 'selected' : ''}>${value}: ${label}</option>`
              ).join('')}
            </select>
          </div>
        </div>
      `;
    } else if (schemaData.prefix_schema === 'isa51' || schemaData.measured_variables) {
      // :isa51 schema - structured prefix fields
      fieldsHtml = `
        <div class="form-group row mb-1">
          <label class="col-form-label col-sm-4" for="tag_measured_variable">Measured Variable</label>
          <div class="col-sm-8">
            <select name="tag[measured_variable]" class="form-select" id="tag_measured_variable" data-action="change->tag#updatePreview">
              <option value="">Select Variable</option>
              ${(schemaData.measured_variables || []).map(([value, label]) =>
                `<option value="${value}" ${value === prefixParts.measured_variable ? 'selected' : ''}>${value}: ${label}</option>`
              ).join('')}
            </select>
          </div>
        </div>

        <div class="form-group row mb-1">
          <label class="col-form-label col-sm-4" for="tag_modifier">Modifier</label>
          <div class="col-sm-8">
            <select name="tag[modifier]" class="form-select" id="tag_modifier" data-action="change->tag#updatePreview">
              <option value="">Select Modifier</option>
              ${(schemaData.modifiers || []).map(([value, label]) =>
                `<option value="${value}" ${value === prefixParts.modifier ? 'selected' : ''}>${value}: ${label}</option>`
              ).join('')}
            </select>
          </div>
        </div>

        <div class="form-group row mb-1">
          <label class="col-form-label col-sm-4" for="tag_function">Function</label>
          <div class="col-sm-8">
            <select name="tag[function]" class="form-select" id="tag_function" data-action="change->tag#updatePreview">
              <option value="">Select Function</option>
              ${this.buildGroupedOptions(schemaData.functions || {}, prefixParts)}
            </select>
          </div>
        </div>

        <div class="form-group row mb-1">
          <label class="col-form-label col-sm-4" for="tag_modifier_function">Modifier Function</label>
          <div class="col-sm-8">
            <select name="tag[modifier_function]" class="form-select" id="tag_modifier_function" data-action="change->tag#updatePreview">
              <option value="">Select Modifier Function</option>
              ${(schemaData.modifier_functions || []).map(([value, label]) =>
                `<option value="${value}" ${value === prefixParts.modifier_function ? 'selected' : ''}>${value}: ${label}</option>`
              ).join('')}
            </select>
          </div>
        </div>
      `;
    } else {
      // :none schema - simple text field
      fieldsHtml = `
        <div class="form-group row mb-1">
          <label class="col-form-label col-sm-4" for="tag_prefix">Prefix</label>
          <div class="col-sm-8">
            <input type="text"
                   name="tag[prefix]"
                   class="form-control"
                   id="tag_prefix"
                   value="${currentPrefix}"
                   placeholder="Enter prefix"
                   data-action="change->tag#updatePreview input->tag#updatePreview">
          </div>
        </div>
      `;
    }

    prefixContainer.innerHTML = fieldsHtml;
  }

  buildGroupedOptions(functions, prefixParts = {}) {
    // Check if this option should be selected (either readout_function or output_function)
    const selectedValue = prefixParts.readout_function || prefixParts.output_function || '';
    return Object.entries(functions).map(([group, options]) =>
      `<optgroup label="${group}">${(options || []).map(([value, label]) =>
        `<option value="${value}" ${value === selectedValue ? 'selected' : ''}>${value}: ${label}</option>`
      ).join('')}</optgroup>`
    ).join('');
  }

  updatePreview() {
    try {
      // Get field values using form elements
      const prefix = this.buildPrefixFromForm(this.element);
      const serial = (this.element.elements['tag[serial]']?.value || '').padStart(4, '0');
      const suffix = this.element.elements['tag[suffix]']?.value || '';

      // Build the full tag with proper separators to match the model
      let fullTag = '';
      if (prefix) {
        fullTag = `${prefix}-${serial}`;
        if (suffix) {
          fullTag += `.${suffix}`;
        }
      }

      // Find and update the preview target (in card header)
      const previewTarget = this.element.closest('.card').querySelector('[data-tag-target="preview"]');
      if (previewTarget) {
        const previewText = fullTag
          ? `${this.modelNameValue}: ${fullTag}`
          : this.defaultTextValue;

        previewTarget.textContent = previewText;
      }

    } catch (error) {
      console.error('Error in updatePreview:', error);
    }
  }

  buildPrefixFromForm(form) {
    // Check if this is an ISA51 form (has measured_variable field)
    const measuredVariable = form.elements['tag[measured_variable]']?.value || '';
    const modifier = form.elements['tag[modifier]']?.value || '';
    const func = form.elements['tag[function]']?.value || '';
    const modifierFunction = form.elements['tag[modifier_function]']?.value || '';

    if (measuredVariable) {
      // ISA51 schema - combine the fields
      return [measuredVariable, modifier, func, modifierFunction].filter(Boolean).join('');
    } else {
      // Simple schema - just get the prefix field
      return form.elements['tag[prefix]']?.value || '';
    }
  }
}
