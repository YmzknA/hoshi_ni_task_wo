export function menuBarHandleScroll() {
// 前回のスクロール位置を記録
let lastScrollY = window.scrollY;

// どれだけスクロールしたら反応するか(px)
const scrollThreshold = 100;

// ボタン要素を取得
const menuBar = document.getElementById('menu_bar');


// ボタンが存在しない場合は処理を終了
if (!menuBar) {
  console.log('menuBarHandleScroll: id="menu_bar"の要素が見つかりません');
  return;
}

// ボタンの初期スタイルを設定
menuBar.style.transition = 'opacity 0.3s ease-in-out, transform 0.3s ease-in-out';

// スクロールを検出する関数
function handleScroll() {
  // 現在のスクロール位置を取得
  const currentScrollY = window.scrollY;

  // スクロール量の差を計算
  const scrollDiff = currentScrollY - lastScrollY;

  // 閾値以上のスクロールがあった場合のみ処理を実行
  if (Math.abs(scrollDiff) > scrollThreshold) {

    if (scrollDiff > 0) {
      // メニューバーを非表示にする
      menuBar.style.opacity = '0';
      menuBar.style.transform = 'translateY(-5px)';
      menuBar.style.pointerEvents = 'none';

    } else {
      // メニューバーを表示する
      menuBar.style.opacity = '1';
      menuBar.style.transform = 'translateY(0)';
      menuBar.style.pointerEvents = 'auto';
    }

    // 前回のスクロール位置を更新
    lastScrollY = currentScrollY;
  }
}

// 一回処理が終わるまで新たに処理をしないようにするフラグ
let actionWate = false;

function requestScrollUpdate() {
  if (!actionWate) {
    requestAnimationFrame(function() {
      handleScroll();
      actionWate = false;
    });
    actionWate = true;
  }
}

// スクロールをリッスン
window.addEventListener('scroll', requestScrollUpdate, { passive: true });
}

