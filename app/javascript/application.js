// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import { bgStarShow } from "./bgStarShow"
import { groupBtnHoverRemoveGroupLinkCardBg } from "./groupBtnHoverRemoveGroupLinkCardBg"
import { addButtonNotification } from "./addButtonNotification"
import { newReleaseNotification } from "./newReleaseNotification"
import { settingButtonRotate } from "./settingButtonRotate"

function initializeApp() {
  // 背景の星を表示
  bgStarShow();

  // ボタンのホバー時にグループリンクカードの背景を変更
  groupBtnHoverRemoveGroupLinkCardBg();


  // 通知ボタンの表示制御
  addButtonNotification();

  // 新リリース通知の表示制御
  newReleaseNotification();

  // 設定ボタンのホバー時のアニメーション
  settingButtonRotate();
}

document.addEventListener("turbo:load", initializeApp);

document.addEventListener("DOMContentLoaded", initializeApp);

