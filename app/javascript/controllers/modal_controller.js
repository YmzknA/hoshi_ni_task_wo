import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["to_not_blur", "slide_top", "close"]

  connect() {
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        this.to_not_blurTarget.classList.add("not_blur");
        setTimeout(() => {
          this.to_not_blurTarget.classList.remove("not_blur");
        }, 500);
      }
    });

    this.closeTargets.forEach((closeTarget) => {
      closeTarget.addEventListener("click", () => {
        this.to_not_blurTarget.classList.add("not_blur");
        setTimeout(() => {
          this.to_not_blurTarget.classList.remove("not_blur");
        }, 500);
      });
    });
  }
}
