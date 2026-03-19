import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 3000 } }

  connect() {
    this.scheduleRefresh()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  scheduleRefresh() {
    this.timer = setTimeout(() => {
      const hasSelection = this.element.querySelector('input[type="radio"]:checked')
      if (!hasSelection) {
        this.element.reload()
      }
      this.scheduleRefresh()
    }, this.intervalValue)
  }
}
