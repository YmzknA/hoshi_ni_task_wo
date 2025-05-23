import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["loading_animation"]
  // ボタンなどにアクションを配置し、loading_animationを開き、loading_ringsを表示する
  // すこしディレイをかけることで、軽いローディングの場合はすこしブラーがかかる程度のエフェクトのみにする
  show() {
    this.timeout = setTimeout(() => {
      requestAnimationFrame(() => {
        this.loading_animationTarget.showModal();
      });
    }, 150);
  }
}
