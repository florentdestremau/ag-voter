import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "row"]

  addChoice() {
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  addDefaults() {
    const defaults = ["Pour", "Contre", "Abstention"]
    defaults.forEach((text, index) => {
      const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime() + index)
      this.containerTarget.insertAdjacentHTML("beforeend", content)
      const rows = this.containerTarget.querySelectorAll("[data-nested-form-target='row']")
      const lastRow = rows[rows.length - 1]
      const textInput = lastRow.querySelector("input[type='text']")
      if (textInput) textInput.value = text
    })

    const otherContent = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime() + 99)
    this.containerTarget.insertAdjacentHTML("beforeend", otherContent)
    const rows = this.containerTarget.querySelectorAll("[data-nested-form-target='row']")
    const otherRow = rows[rows.length - 1]
    const textInput = otherRow.querySelector("input[type='text']")
    if (textInput) textInput.value = "Autre"
    const checkbox = otherRow.querySelector("input[type='checkbox']")
    if (checkbox) checkbox.checked = true
  }

  removeChoice(event) {
    const row = event.target.closest("[data-nested-form-target='row']")
    const destroyField = row.querySelector("[data-nested-form-target='destroy']")
    const idField = row.querySelector("input[name*='[id]']")
    if (!idField || !idField.value) {
      row.remove()
      return
    }
    if (destroyField) {
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
