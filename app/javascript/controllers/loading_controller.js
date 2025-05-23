import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["loading_animation", "loading_rings"]

  // 接続時、loading_animationを閉じ、loading_ringsを非表示にする
  connect() {
    this.loading_animationTarget.close();
    this.loading_ringsTarget.classList.add("hidden");
  }

  // ボタンなどにアクションを配置し、loading_animationを開き、loading_ringsを表示する
  // すこしディレイをかけることで、軽いローディングの場合はすこしブラーがかかる程度のエフェクトのみにする
  show() {
    this.loading_ringsTarget.classList.add("hidden");
    this.loading_animationTarget.showModal();
    this.timeout = setTimeout(() => {
      this.loading_ringsTarget.classList.remove("hidden");
    }, 200);
  }
}
