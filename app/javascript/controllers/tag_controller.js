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
    var disciplineSelect = this.element.querySelector('[name*="[discipline_id]"]');
    console.log('updateFormStructure: disciplineSelect', disciplineSelect);
    if (!disciplineSelect?.value) {
      console.log('updateFormStructure: no discipline value');
      return;
    }
    
    console.log('updateFormStructure: fetching schema for discipline', disciplineSelect.value);
    fetch('/disciplines/' + disciplineSelect.value + '/schema.json')
      .then(r => {
        console.log('updateFormStructure: response status', r.status);
        return r.json();
      })
      .then(data => {
        console.log('updateFormStructure: schema data received', data);
        this.renderFormFields(data);
      })
      .catch(error => {
        console.error('updateFormStructure: error', error);
      });
  }

  handleFormUpdate(event) {
    var target = event.target;
    
    // Handle discipline changes
    if (target.matches('[name*="[discipline_id]"]')) {
      this.updateFormStructure();
      return;
    }
    
    // Handle prefix field changes (any of the new dynamic fields)
    if (target.matches('[name*="[prefix]"], [name*="[serial]"], [name*="[suffix]"], [name="measured_variable"], [name="modifier"], [name="function"], [name="modifier_function"], [name="part1"], [name="part2"], [name="prefix_select"]')) {
      this.debouncedUpdatePreview();
    }
  }

  renderFormFields(schemaData) {
    console.log('renderFormFields called with', schemaData);
    var prefixContainer = this.element.querySelector('[data-tag-prefix-container]');
    console.log('prefixContainer found', !!prefixContainer);
    if (!prefixContainer) return;

    var currentPrefix = prefixContainer.dataset.currentPrefix || '';
    var prefixParts = JSON.parse(prefixContainer.dataset.prefixParts || '{}');
    var translations = JSON.parse(prefixContainer.dataset.translations || '{}');
    var formPrefix = prefixContainer.dataset.formPrefix || 'tag';

    var fieldsHtml = '';
    var schemaType = schemaData.type || 'default';
    console.log('schemaType', schemaType);
    
    if (schemaType === 'default') {
      fieldsHtml = '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="' + formPrefix + '_prefix">' + translations.prefix + '</label>' +
        '<div class="col-sm-8">' +
        '<input type="text" name="' + formPrefix + '[prefix]" class="form-control" id="' + formPrefix + '_prefix" ' +
        'value="' + currentPrefix + '" placeholder="' + translations.prefix + '" ' +
        'data-action="change->tag#updatePreview input->tag#updatePreview">' +
        '</div></div>';
        
    } else if (schemaType === 'dim1') {
      console.log('Rendering dim1 schema');
      fieldsHtml = '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="' + formPrefix + '_prefix_select">' + translations.prefix + '</label>' +
        '<div class="col-sm-8">' +
        '<select name="prefix_select" class="form-select" id="' + formPrefix + '_prefix_select" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
      for (var key in schemaData.prefixes) {
        var selected = key === currentPrefix ? 'selected' : '';
        fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.prefixes[key] + '</option>';
      }
      fieldsHtml += '</select></div></div>';
      
      // Add read-only prefix field for dim1 schema
      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-3">' + translations.prefix + '</label>';
      fieldsHtml += '<div class="col-sm-3">' +
        '<input type="text" name="' + formPrefix + '[prefix]" class="form-control-plaintext" readonly ' +
        'value="' + currentPrefix + '" ' +
        'data-tag-target="prefixField">' +
        '</div></div>';
        
    } else if (schemaType === 'dim2') {
      console.log('Rendering dim2 schema')
      fieldsHtml = '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="' + formPrefix + '_part1">' + translations.part1 + '</label>' +
        '<div class="col-sm-8">' +
        '<select name="part1" class="form-select" id="' + formPrefix + '_part1" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
      for (var key in schemaData.part1) {
        var selected = key === (prefixParts.part1 || '') ? 'selected' : '';
        fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.part1[key] + '</option>';
      }
      fieldsHtml += '</select></div></div>';
      
      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="' + formPrefix + '_part2">' + translations.part2 + '</label>' +
        '<div class="col-sm-8">' +
        '<select name="part2" class="form-select" id="' + formPrefix + '_part2" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
      for (var key in schemaData.part2) {
        var selected = key === (prefixParts.part2 || '') ? 'selected' : '';
        fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.part2[key] + '</option>';
      }
      fieldsHtml += '</select></div></div>';
      
      // Add read-only prefix field for dim2 schema
      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-3">' + translations.prefix + '</label>';
      fieldsHtml += '<div class="col-sm-3">' +
        '<input type="text" name="' + formPrefix + '[prefix]" class="form-control-plaintext" readonly ' +
        'value="' + currentPrefix + '" ' +
        'data-tag-target="prefixField">' +
        '</div></div>';
        
    } else if (schemaType === 'isa51') {
      console.log('Rendering isa51 schema');
      fieldsHtml = '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="_measured_variable">' + translations.measured_variable + '</label>' +
        '<div class="col-sm-8">' +
        '<select name="measured_variable" class="form-select" id="_measured_variable" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
      for (var key in schemaData.measured_variables) {
        var selected = key === (prefixParts.measured_variable || '') ? 'selected' : '';
        fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.measured_variables[key] + '</option>';
      }
      fieldsHtml += '</select></div></div>';
      
      if (schemaData.modifiers) {
        fieldsHtml += '<div class="form-group row mb-3">' +
          '<label class="col-form-label col-sm-4" for="_modifier">' + 
          translations.modifier + '</label>';
        fieldsHtml += '<div class="col-sm-8">' +
          '<select name="modifier" class="form-select" id="_modifier" data-action="change->tag#updatePreview">' +
          '<option value="">' + translations.select_option + '</option>';
        for (var key in schemaData.modifiers) {
          var selected = key === (prefixParts.modifier || '') ? 'selected' : '';
          fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.modifiers[key] + '</option>';
        }
        fieldsHtml += '</select></div></div>';
      }

      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-4" for="_function">' + 
        translations.function + '</label>';
      fieldsHtml += '<div class="col-sm-8">' +
        '<select name="function" class="form-select" id="_function" data-action="change->tag#updatePreview">' +
        '<option value="">' + translations.select_option + '</option>';
      
      if (schemaData.readout_functions) {
        fieldsHtml += '<optgroup label="Readout Functions">';
        for (var key in schemaData.readout_functions) {
          var selected = key === (prefixParts.readout_function || '') ? 'selected' : '';
          fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.readout_functions[key] + '</option>';
        }
        fieldsHtml += '</optgroup>';
      }
      
      if (schemaData.output_functions) {
        fieldsHtml += '<optgroup label="Output Functions">';
        for (var key in schemaData.output_functions) {
          var selected = key === (prefixParts.output_function || '') ? 'selected' : '';
          fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.output_functions[key] + '</option>';
        }
        fieldsHtml += '</optgroup>';
      }
      
      fieldsHtml += '</select></div></div>';

      if (schemaData.modifier_functions) {
        fieldsHtml += '<div class="form-group row mb-3">' +
          '<label class="col-form-label col-sm-4" for="_modifier_function">' + 
          translations.modifier_function + '</label>';
        fieldsHtml += '<div class="col-sm-8">' + 
          '<select name="modifier_function" class="form-select" id="_modifier_function" data-action="change->tag#updatePreview">' +
          '<option value="">' + translations.select_option + '</option>';
        for (var key in schemaData.modifier_functions) {
          var selected = key === (prefixParts.modifier_function || '') ? 'selected' : '';
          fieldsHtml += '<option value="' + key + '" ' + selected + '>' + key + ': ' + schemaData.modifier_functions[key] + '</option>';
        }
        fieldsHtml += '</select></div></div>';
      }
      
      // Add read-only prefix field for ISA51 schema
      fieldsHtml += '<div class="form-group row mb-3">' +
        '<label class="col-form-label col-sm-3">' + translations.prefix + '</label>';
      fieldsHtml += '<div class="col-sm-3">' +
        '<input type="text" name="' + formPrefix + '[prefix]" class="form-control-plaintext" readonly ' +
        'value="' + currentPrefix + '" ' +
        'data-tag-target="prefixField">' +
        '</div></div>';
    }

    console.log('fieldsHtml', fieldsHtml);
    prefixContainer.innerHTML = fieldsHtml;
    console.log('innerHTML set, new content:', prefixContainer.innerHTML);
  }


  updatePreview() {
    var prefixContainer = this.element.querySelector('[data-tag-prefix-container]');
    if (!prefixContainer) return;
    
    var formPrefix = prefixContainer.dataset.formPrefix || 'tag';
    var prefix = this.buildPrefixFromForm(this.element);
    
    // Update the prefix field
    var prefixField = this.element.querySelector('[name*="[prefix]"]');
    if (prefixField) prefixField.value = prefix;
    
    // Get serial and suffix
    var serialField = this.element.querySelector('[name*="[serial]"]');
    var serial = serialField?.value || '';
    var suffix = this.element.querySelector('[name*="[suffix]"]')?.value || '';
    
    // Format serial for display only (don't modify the field)
    var displaySerial = serial.replace(/\D/g, '').padStart(4, '0');
    
    // Build full tag
    var fullTag = prefix ? prefix + '-' + displaySerial + (suffix ? '.' + suffix : '') : '';
    
    // Update preview
    var previewElement = this.element.closest('.card')?.querySelector('[data-tag-target="preview"]');
    if (previewElement) {
      previewElement.textContent = fullTag ? this.modelNameValue + ': ' + fullTag : this.defaultTextValue;
    }
  }

  buildPrefixFromForm(form) {
    var measuredVariable = form.querySelector('[name="measured_variable"]')?.value;
    if (measuredVariable) {
      // ISA51 schema
      var parts = [measuredVariable];
      var modifier = form.querySelector('[name="modifier"]')?.value;
      if (modifier) parts.push(modifier);
      var func = form.querySelector('[name="function"]')?.value;
      if (func) parts.push(func);
      var modifierFunction = form.querySelector('[name="modifier_function"]')?.value;
      if (modifierFunction) parts.push(modifierFunction);
      return parts.join('');
    }
    
    var part1 = form.querySelector('[name="part1"]')?.value;
    if (part1) {
      // dim2 schema
      var part2 = form.querySelector('[name="part2"]')?.value;
      return part2 ? part1 + part2 : part1;
    }
    
    var prefixSelect = form.querySelector('[name="prefix_select"]')?.value;
    if (prefixSelect) {
      // dim1 schema
      return prefixSelect;
    }
    
    // default schema
    return form.querySelector('[name*="[prefix]"]')?.value || '';
  }
}
