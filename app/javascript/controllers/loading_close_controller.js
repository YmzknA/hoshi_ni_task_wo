import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading-close"
export default class extends Controller {

  connect() {
    const loading = document.querySelector("#loading");
    loading.close();

    // loading_controllerのタイムアウトをキャンセル
    if (window.loadingTimeout) {
      clearTimeout(window.loadingTimeout);
      window.loadingTimeout = null;
    }

    this.timeout = setTimeout(() => {
      loading.close();
    }, 50);
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }
}
