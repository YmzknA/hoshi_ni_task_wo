import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["loading_animation", "loading_top", "loading_rings"]

  connect() {
    this.loading_animationTarget.close();
    this.loading_ringsTarget.classList.add("hidden");
  }

  show() {
    this.loading_animationTarget.showModal();
    this.timeout = setTimeout(() => {
      this.loading_ringsTarget.classList.remove("hidden");
    }, 100)
  }

}
