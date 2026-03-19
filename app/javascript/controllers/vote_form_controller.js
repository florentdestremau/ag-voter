import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["otherField", "freeText", "submit"]

  toggleOther(event) {
    const isOther = event.target.dataset.voteFormIsOtherValue === "true"
    if (this.hasOtherFieldTarget) {
      this.otherFieldTarget.style.display = isOther ? "block" : "none"
    }
    if (isOther && this.hasFreeTextTarget) {
      this.freeTextTarget.focus()
    }
  }

  disableOnSubmit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.value = "Vote en cours..."
    }
  }
}
