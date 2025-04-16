import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="show-modal"
export default class extends Controller {
  static targets = ["task_modal", "modal_top"]

  connect() {
    this.task_modalTarget.showModal();
  }

  disconnect() {
    this.modal_topTarget.innerHTML = "";
  }

}
