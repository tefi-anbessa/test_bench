import { Controller } from "@hotwired/stimulus"
// tom-select's pinned build is a UMD bundle (see config/importmap.rb) -
// it attaches window.TomSelect rather than exporting an ESM binding, same
// as bootstrap/pagy already do in app/javascript/application.js.
import "tom-select"

// Connects to data-controller="tom-select" - generic, reusable type-ahead/
// remote-search enhancement for any <select>, not tied to any one field or
// model. Configured entirely through data attributes:
//
//   data-tom-select-url-value           (optional) a JSON search endpoint -
//     when present, the server only ever has to render the currently-
//     selected option (if any); everything else is fetched as the user
//     types. When absent, Tom Select just adds search/type-ahead over
//     whatever <option>s are already rendered - no remote calls at all.
//   data-tom-select-value-field-value   (default "id")
//   data-tom-select-label-field-value   (default "text")
//   data-tom-select-search-field-value  (JSON array, default: [labelField])
//   data-tom-select-display-fields-value (JSON array, default: [labelField]) -
//     which JSON keys to show, in order, for both the dropdown list and the
//     selected item - joined with an em dash. Lets a result show more than
//     just its label (e.g. a tag plus its discipline code and service
//     description) without the controller knowing what any of those fields
//     mean.
//   data-tom-select-params-value        (optional JSON object) - extra
//     query params sent with every search request alongside "q" (e.g. a
//     record id to exclude, a scope to filter by) - the controller has no
//     knowledge of what these mean, it just passes them through.
//
// Each endpoint is expected to return a JSON array of objects shaped like
// { [valueField]: ..., [labelField]: ..., ...any other displayFields/searchField keys }.
export default class extends Controller {
  static values = {
    url: String,
    valueField: { type: String, default: "id" },
    labelField: { type: String, default: "text" },
    searchField: Array,
    displayFields: Array,
    params: Object
  }

  connect() {
    const displayFields = this.hasDisplayFieldsValue && this.displayFieldsValue.length
      ? this.displayFieldsValue
      : [this.labelFieldValue]

    const renderRow = (data, escape) =>
      `<div>${displayFields.map(field => data[field]).filter(Boolean).map(escape).join(" &mdash; ")}</div>`

    const options = {
      valueField: this.valueFieldValue,
      labelField: this.labelFieldValue,
      searchField: this.hasSearchFieldValue && this.searchFieldValue.length ? this.searchFieldValue : [this.labelFieldValue],
      render: { option: renderRow, item: renderRow }
    }

    if (this.hasUrlValue) {
      options.load = (query, callback) => {
        const params = new URLSearchParams({ q: query, ...this.paramsValue })
        fetch(`${this.urlValue}?${params}`)
          .then(response => response.json())
          .then(data => callback(data))
          .catch(() => callback())
      }
    }

    this.tomSelect = new window.TomSelect(this.element, options)
  }

  disconnect() {
    // Tom Select rewrites the DOM around the original <select> - without
    // this, Turbo's page caching can leave a stale instance attached to a
    // detached element.
    this.tomSelect?.destroy()
  }
}
