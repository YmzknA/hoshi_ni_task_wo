import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading-close"
export default class extends Controller {
  connect() {
    const loading = document.querySelector("#loading");
    const loadingRings = document.querySelector("#loading_rings");
    loading.close();
    loadingRings.classList.add("hidden");
  }
}
