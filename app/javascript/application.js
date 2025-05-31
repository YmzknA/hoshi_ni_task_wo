// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import { bgStarShow } from "./bgStarShow"
import { groupBtnHoverRemoveGroupLinkCardBg } from "./groupBtnHoverRemoveGroupLinkCardBg"
import { fadeElementOnScroll } from "./menuBarHandleScroll"
import { addButtonNotification } from "./addButtonNotification"

function initializeApp() {
  // 背景の星を表示
  bgStarShow();

  // ボタンのホバー時にグループリンクカードの背景を変更
  groupBtnHoverRemoveGroupLinkCardBg();

  // スクロール時のボタン表示/非表示を制御
  fadeElementOnScroll('add_button');
  fadeElementOnScroll('menu_bar');

  // 通知ボタンの表示制御
  addButtonNotification();
}

document.addEventListener("turbo:load", initializeApp);

document.addEventListener("DOMContentLoaded", initializeApp);
