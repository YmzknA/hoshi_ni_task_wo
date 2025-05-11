// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import { bgStarShow } from "./bgStarShow"
import { groupBtnHoverRemoveGroupLinkCardBg } from "./groupBtnHoverRemoveGroupLinkCardBg"

document.addEventListener("turbo:load", function() {
  // 背景の星を表示
  bgStarShow();

  // 完了ボタンのホバー時にグループリンクカードの背景を変更
  groupBtnHoverRemoveGroupLinkCardBg();
});

document.addEventListener("DOMContentLoaded", function() {
  // 背景の星を表示
  bgStarShow();

  // 完了ボタンのホバー時にグループリンクカードの背景を変更
  groupBtnHoverRemoveGroupLinkCardBg();
});
