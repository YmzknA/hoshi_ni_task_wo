import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["loading_animation"]
  // ボタンなどにアクションを配置し、loading画面を表示する
  // すこしディレイをかけることで、軽いローディングの場合はローディング画面が表示されないように
  show() {
    this.timeout = setTimeout(() => {
      this.loading_animationTarget.showModal();
    }, 150);
  }

  disconnect() {
    console.log("disconnect");
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
    // ローディングアニメーションを閉じる
    this.loading_animationTarget.close();
  }
}
