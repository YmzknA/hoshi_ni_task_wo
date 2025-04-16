import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="show-modal"
export default class extends Controller {
  static targets = ["task_modal"]

  connect() {
  }


}
