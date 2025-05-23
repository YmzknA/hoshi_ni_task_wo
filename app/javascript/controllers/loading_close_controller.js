import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading-close"
export default class extends Controller {

  // 接続時、loading_animationを閉じ、loading_ringsを非表示にする
  connect() {
    const loading = document.querySelector("#loading");
    loading.close();

    this.timeout = setTimeout(() => {
    loading.close();
    }, 150);
  }
}
