import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }
  static targets = ["button"]

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      if (this.hasButtonTarget) {
        const original = this.buttonTarget.textContent
        this.buttonTarget.textContent = "Copié !"
        setTimeout(() => { this.buttonTarget.textContent = original }, 2000)
      }
    })
  }
}
