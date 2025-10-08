import { Controller } from "@hotwired/stimulus"

// Simple debounce helper - compatible with older JavaScript
function debounce(func, wait) {
  var timeout;
  return function() {
    var context = this;
    var args = arguments;
    var later = function() {
      timeout = null;
      func.apply(context, args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

export default class extends Controller {
  static targets = ["preview", "discipline", "prefixContainer", "prefixField"]
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
    var initialDiscipline = this.element.querySelector('[name="tag[discipline_id]"]')?.value ||
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

  updateFormStructure() {
    // This method fetches and renders the appropriate form fields based on the selected discipline
    var disciplineSelect = this.element.querySelector('[name="tag[discipline_id]"]') ||
                          this.element.querySelector('[name*="[discipline_id]"]') ||
                          this.element.querySelector('select[name*="discipline"]');
    if (!disciplineSelect || !disciplineSelect.value) return;

    var disciplineId = disciplineSelect.value;
    
    // Fetch schema data for this discipline
    fetch('/tags/schema_data?discipline_id=' + disciplineId, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      },
      credentials: 'same-origin'
    })
    .then(function(response) {
      if (response.ok) {
        return response.json();
      }
      throw new Error('Network response was not ok');
    })
    .then(function(schemaData) {
      this.renderFormFields(schemaData);
    }.bind(this))
    .catch(function(error) {
      console.error('Error fetching schema data:', error);
    });
  }

  async handleFormUpdate(event) {
    var target = event.target;
    var prefixContainer = this.element.querySelector('[data-tag-prefix-container]');
    if (!prefixContainer) return;

    // Get the form prefix from the container
    var formPrefix = prefixContainer.dataset.formPrefix || 'tag';
    
    // Format the form prefix for attribute matching
    if (formPrefix.endsWith(']')) {
      // Keep as is
    } else if (formPrefix.includes('_attributes]')) {
      formPrefix = formPrefix.replace('_attributes]', ']');
    } else {
      formPrefix = 'tag';
    }

    // Handle discipline changes
    if (target.matches('[name*="[discipline_id]"]')) {
      this.updateFormStructure();
    }

    // Handle prefix field updates (any of the new dynamic fields)
    var prefixSelectors = [
      '[name$="' + formPrefix + '[prefix]"]',
      '[name$="' + formPrefix + '[serial]"]',
      '[name$="' + formPrefix + '[suffix]"]',
      '[name="measured_variable"]',
      '[name="modifier"]',
      '[name="function"]',
      '[name="modifier_function"]',
      '[name*="' + formPrefix + '[prefix_attributes][prefix]"]',
      '[name*="' + formPrefix + '[prefix_attributes][serial]"]',
      '[name*="' + formPrefix + '[prefix_attributes][suffix]"]',
      '[name*="' + formPrefix + '[tag_attributes][prefix]"]',
      '[name*="' + formPrefix + '[tag_attributes][serial]"]',
      '[name*="' + formPrefix + '[tag_attributes][suffix]"]'
    ];

    if (target.matches(prefixSelectors.join(', '))) {
      this.debouncedUpdatePreview();
    }
    
    // Only proceed with AJAX call if this is a discipline change
    if (!target.matches('[name*="[discipline_id]"]')) {
      return;
    }
  }

  renderFormFields(schemaData) {
    // Find the container for prefix fields within the form
    var prefixContainer = this.element.querySelector('[data-tag-prefix-container]');
    if (!prefixContainer) return;

    // Get current values from data attributes
    var currentPrefix = prefixContainer.dataset.currentPrefix || '';
    var prefixParts = JSON.parse(prefixContainer.dataset.prefixParts || '{}');
    var disciplineId = prefixContainer.dataset.disciplineId || '';
    var hasSchema = prefixContainer.dataset.hasSchema === 'true';
    var formPrefix = prefixContainer.dataset.formPrefix || 'tag';
    
    // Ensure form prefix is properly formatted for nested attributes
    if (formPrefix.endsWith(']')) {
      // If it's already in the format 'parent[child]', use it as is
    } else if (formPrefix.includes('_attributes]')) {
      // If it's in the format 'parent[child_attributes]', convert to 'parent[child]'
      formPrefix = formPrefix.replace('_attributes]', ']');
    } else {
      // Default to 'tag' if format is unexpected
      formPrefix = 'tag';
    }

    // Get translations from data attributes
    var translations = JSON.parse(prefixContainer.dataset.translations || '{}');

    var fieldsHtml = '';
    console.log('Schema data received:', schemaData);
console.log('Functions data:', schemaData.functions);
console.log('Modifier functions data:', schemaData.modifier_functions);

    if (schemaData.prefix_schema === 'dim1' || schemaData.prefixes) {
      // :dim1 schema - simple prefix selection
      fieldsHtml = '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="' + formPrefix + '_prefix">' + translations.prefix + '</label>' +
        '<div class="col-sm-8">' +
        '<select name="' + formPrefix + '[prefix]" class="form-select" id="' + formPrefix + '_prefix" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
      
      if (schemaData.prefixes) {
        for (var i = 0; i < schemaData.prefixes.length; i++) {
          var option = schemaData.prefixes[i];
          var selected = option[0] === currentPrefix ? 'selected' : '';
          fieldsHtml += '<option value="' + option[0] + '" ' + selected + '>' + option[0] + ': ' + option[1] + '</option>';
        }
      }
      fieldsHtml += '</select></div></div>';

    } else if (schemaData.prefix_schema === 'isa51') {
      // :isa51 schema - structured prefix fields
      fieldsHtml = '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="_measured_variable">' + translations.measured_variable + '</label>' +
        '<div class="col-sm-8">' +
        '<select name="measured_variable" class="form-select" id="_measured_variable" data-action="change->tag#updatePreview">'
        '<option value="">' + translations.select_option + '</option>';
      
      if (schemaData.measured_variables) {
        for (var i = 0; i < schemaData.measured_variables.length; i++) {
          var option = schemaData.measured_variables[i];
          var selected = option[0] === prefixParts.measured_variable ? 'selected' : '';
          fieldsHtml += '<option value="' + option[0] + '" ' + selected + '>' + option[0] + ': ' + option[1] + '</option>';
        }
      }
      fieldsHtml += '</select></div></div>';
      
      if (schemaData.modifiers) {
        // Modifier field
        fieldsHtml += '<div class="form-group row mb-3">' +
          '<label class="col-form-label col-sm-4" for="_modifier">' + 
          translations.modifier + '</label>';
        fieldsHtml += '<div class="col-sm-8">' +
          '<select name="modifier" class="form-select" id="_modifier" data-action="change->tag#updatePreview">' +
          '<option value="">' + translations.select_option + '</option>';

        for (var i = 0; i < schemaData.modifiers.length; i++) {
          var option = schemaData.modifiers[i];
          var selected = (option[0] === prefixParts.modifier) ? 'selected' : '';
          fieldsHtml += '<option value="' + option[0] + '" ' + selected + '>' + 
            option[0] + ': ' + option[1] + '</option>';
        }
      }
      fieldsHtml += '</select></div></div>';

      // Function field
      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="' + '_function">' + 
        translations.function + '</label>';
      fieldsHtml += '<div class="col-sm-8">' +
        '<select name="function" class="form-select" id="_function" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
    
      if (schemaData.functions) {
        var functionsHtml = this.buildGroupedOptions(schemaData.functions, prefixParts);
        fieldsHtml += functionsHtml;
      }
      fieldsHtml += '</select></div></div>';

      // Modifier function field
      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="_modifier_function">' + 
        translations.modifier_function + '</label>';

      fieldsHtml += '<div class="col-sm-8">' + 
        '<select name="modifier_function" class="form-select" id="_modifier_function" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
      
      if (schemaData.modifier_functions) {
        for (var i = 0; i < schemaData.modifier_functions.length; i++) {
          var option = schemaData.modifier_functions[i];
          var selected = option[0] === prefixParts.modifier_function ? 'selected' : '';
          fieldsHtml += '<option value="' + option[0] + '" ' + selected + '>' + 
            option[0] + ': ' + option[1] + '</option>';
        }
      }
      fieldsHtml += '</select></div></div>';
      
    // Add read-only prefix field for ISA51 schema
      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-3">' + translations.prefix + '</label>';
      fieldsHtml += '<div class="col-sm-3">' +
        '<input type="text" name="' + formPrefix + '[prefix]" class="form-control-plaintext" readonly ' +
        'value="' + currentPrefix + '" ' +
        'data-tag-target="prefixField">' +
        '</div></div>';


    } else {
      // :none schema - simple text field
      fieldsHtml = '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="' + formPrefix + '_prefix">' + translations.prefix + '</label>' +
        '<div class="col-sm-8">' +
        '<input type="text" name="' + formPrefix + '[prefix]" class="form-control" id="' + formPrefix + '_prefix" ' +
        'value="' + currentPrefix + '" placeholder="' + translations.prefix + '" ' +
        'data-action="change->tag#updatePreview input->tag#updatePreview">' +
        '</div></div>';
    }

    prefixContainer.innerHTML = fieldsHtml;
  }

  buildGroupedOptions(functions, prefixParts) {
    if (!functions || typeof functions !== 'object') return '';
    
    // Check both possible function types in prefixParts
    var selectedValue = prefixParts.readout_function || prefixParts.output_function || '';
    var optionsHtml = '';
    
    for (var group in functions) {
      if (functions.hasOwnProperty(group)) {
        optionsHtml += '<optgroup label="' + group + '">';
        var options = functions[group];
        if (Array.isArray(options)) {
          for (var i = 0; i < options.length; i++) {
            var option = options[i];
            // Check if this option matches either function type
            var selected = (option[0] === selectedValue) ? 'selected' : '';
            optionsHtml += '<option value="' + option[0] + '" ' + selected + '>' + 
                          option[0] + ': ' + option[1] + '</option>';
          }
        }
        optionsHtml += '</optgroup>';
      }
    }
    return optionsHtml;
  }

  updatePreview() {
    try {
      // Get the form prefix from the container
      var prefixContainer = this.element.querySelector('[data-tag-prefix-container]');
      if (!prefixContainer) return;
      
      // Get the form prefix (e.g., 'tag' or 'switchboard[tag_attributes]')
      var formPrefix = prefixContainer.dataset.formPrefix || 'tag';
      if (formPrefix.endsWith(']')) {
        // Already in the format we need
      } else if (formPrefix.includes('_attributes]')) {
        formPrefix = formPrefix.replace('_attributes]', ']');
      } else {
        formPrefix = 'tag';
      }
      
      // Build the combined prefix from form fields
      var prefix = this.buildPrefixFromForm(this.element);
      
      // Update the prefix field (using the target)
      if (this.hasPrefixFieldTarget) {
        this.prefixFieldTarget.value = prefix;
      }
      
      // Get serial and suffix values
      var serialField = this.element.querySelector('[name$="' + formPrefix + '[serial]"]');
      var suffixField = this.element.querySelector('[name$="' + formPrefix + '[suffix]"]');
      var serial = (serialField ? serialField.value : '') || '';
      var suffix = (suffixField ? suffixField.value : '') || '';
      
      // Pad serial to 4 digits
      serial = serial.padStart ? serial.padStart(4, '0') : serial;

      // Build the full tag with proper separators to match the model
      var fullTag = '';
      if (prefix) {
        fullTag = prefix + '-' + serial;
        if (suffix) {
          fullTag += '.' + suffix;
        }
      }

      // Find and update the preview target (in card header)
      var previewTarget = this.element.closest('.card');
      if (previewTarget) {
        var previewElement = previewTarget.querySelector('[data-tag-target="preview"]');
        if (previewElement) {
          var previewText = fullTag ? this.modelNameValue + ': ' + fullTag : this.defaultTextValue;
          previewElement.textContent = previewText;
        }
      }

    } catch (error) {
      console.error('Error in updatePreview:', error);
    }
  }

  buildPrefixFromForm(form) {
    // Get the form prefix from the container
    var prefixContainer = this.element.querySelector('[data-tag-prefix-container]');
    if (!prefixContainer) return '';
    
    var formPrefix = prefixContainer.dataset.formPrefix || 'tag';
    if (formPrefix.endsWith(']')) {
      // Already in the format we need
    } else if (formPrefix.includes('_attributes]')) {
      formPrefix = formPrefix.replace('_attributes]', ']');
    } else {
      formPrefix = 'tag';
    }
    
    // Helper function to get field value by name pattern
    var getFieldValue = function(fieldName) {
      var field = form.querySelector('[name="' + fieldName + '"]');
      return field ? field.value : '';
    };
    
    // Check if this is an ISA51 form (has measured_variable field)
    var measuredVariable = getFieldValue('measured_variable');
    var modifier = getFieldValue('modifier');
    var func = getFieldValue('function');
    var modifierFunction = getFieldValue('modifier_function');

    if (measuredVariable) {
      // ISA51 schema - combine the fields
      var parts = [measuredVariable, modifier, func, modifierFunction].filter(function(part) {
        return part && part.length > 0;
      });
      return parts.join('');
    } else {
      // Simple schema - just get the prefix field
      var prefixField = form.querySelector('[name="tag[prefix]"]');
      return prefixField ? prefixField.value : '';
    }
  }
}
