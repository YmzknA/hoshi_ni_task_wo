import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["loading_animation"]
  // ボタンなどにアクションを配置し、loading画面を表示する
  // すこしディレイをかけることで、軽いローディングの場合はローディング画面が表示されないように
  show() {
    this.timeout = setTimeout(() => {
      requestAnimationFrame(() => {
        this.loading_animationTarget.showModal();
      });
    }, 150);
  }
}
