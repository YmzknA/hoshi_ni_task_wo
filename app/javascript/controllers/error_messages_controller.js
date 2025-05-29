import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="error-messages"
export default class extends Controller {
  static targets = ["errorMessage"]

  connect() {
    this.errorMessageTargets.forEach((element) => {
      element.scrollIntoView({ behavior: "smooth", block: "center" });
    })
  }
}
