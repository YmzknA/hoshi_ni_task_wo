import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="confirm-delete"
export default class extends Controller {
  static targets = ["input", "button", "message"]
  static values = { expectedName: String }

  connect() {
    this.validate()
  }

  validate() {
    const currentValue = this.inputTarget.value
    const matches = currentValue === this.expectedNameValue
    const hasValue = currentValue.length > 0

    this.toggleButton(matches)
    this.updateMessage(matches, hasValue)
  }

  toggleButton(isEnabled) {
    this.buttonTarget.disabled = !isEnabled
    this.buttonTarget.classList.toggle("btn-disabled", !isEnabled)
  }

  updateMessage(matches, hasValue) {
    this.messageTarget.classList.remove("text-error", "text-success")

    if (matches) {
      this.messageTarget.textContent = "入力値が一致しました。"
      this.messageTarget.classList.add("text-success")
      return
    }

    if (hasValue) {
      this.messageTarget.textContent = "入力値が一致しません。"
      this.messageTarget.classList.add("text-error")
      return
    }

    this.messageTarget.textContent = ""
  }
}
