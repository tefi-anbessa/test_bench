import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "prefix", "part1", "part2", "measuredVariable", "modifier", "function", "modifierFunction" ]

  connect() {
    console.log('Tag Prefix controller connected', this.element);
  }

  disconnect() {
    console.log('Tag Prefix controller disconnected', this.element);
  }

  updatePrefix() {
    console.log('Tag Prefix update action invoked', this.element);
    let prefix;
    if (this.hasMeasuredVariableTarget) {
      prefix = [
        this.measuredVariableTarget.value,
        this.modifierTarget.value,
        this.functionTarget.value,
        this.modifierFunctionTarget.value 
      ]
    }
    else if (this.hasPart1Target) {
      prefix = [
        this.part1Target.value,
        this.part2Target.value
      ]
    }
    else {
      console.log('No valid target found');
      prefix = []
    }

    this.prefixTarget.value = prefix.filter(Boolean).join('')
  }
}
