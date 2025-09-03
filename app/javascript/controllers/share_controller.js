import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.urlValue = this.element.dataset.shareUrl
  }

  async copy() {
    if (!this.urlValue) return

    try {
      await navigator.clipboard.writeText(this.urlValue)
      alert("Public link copied to clipboard!")
    } catch (err) {
      alert("Failed to copy link: " + err)
    }
  }

  click(event) {
    event.preventDefault()
    this.copy()
  }
}
