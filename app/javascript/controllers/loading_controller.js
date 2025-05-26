import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["loading_animation"]
  // ボタンなどにアクションを配置し、loading画面を表示する
  // すこしディレイをかけることで、軽いローディングの場合はローディング画面が表示されないように
  show() {
    // グローバルに変数を保存してキャンセル可能にする
    window.loadingTimeout = setTimeout(() => {
      this.loading_animationTarget.showModal();
    }, 300);
  }

  disconnect() {
    if (window.loadingTimeout) {
      clearTimeout(window.loadingTimeout);
      window.loadingTimeout = null;
    }
    // ローディングアニメーションを閉じる
    this.loading_animationTarget.close();
  }
}
