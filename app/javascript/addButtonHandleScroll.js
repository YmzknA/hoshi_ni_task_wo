export function addButtonHandleScroll() {
// 前回のスクロール位置を記録
let lastScrollY = window.scrollY;

// どれだけスクロールしたら反応するか(px)
const scrollThreshold = 100;

// ボタン要素を取得
const addButton = document.getElementById('add_button');

// ボタンが存在しない場合は処理を終了
if (!addButton) {
  console.log('addButtonHandleScroll: id="add_button"の要素が見つかりません');
  return;
}

// ボタンの初期スタイルを設定
addButton.style.transition = 'opacity 0.3s ease-in-out, transform 0.3s ease-in-out';

// スクロールを検出する関数
function handleScroll() {
  // 現在のスクロール位置を取得
  const currentScrollY = window.scrollY;

  // スクロール量の差を計算
  const scrollDiff = currentScrollY - lastScrollY;

  // 閾値以上のスクロールがあった場合のみ処理を実行
  if (Math.abs(scrollDiff) > scrollThreshold) {

    if (scrollDiff > 0) {
      // 下方向にスクロールするとボタンを非表示にする
      addButton.style.opacity = '0';
      addButton.style.transform = 'translateY(-5px)';
      // ポインターイベントも無効化（クリックできないようにする）
      addButton.style.pointerEvents = 'none';

    } else {
      // 上方向にスクロールするとボタンを表示する
      addButton.style.opacity = '1';
      addButton.style.transform = 'translateY(0)';
      // ポインターイベントを有効化
      addButton.style.pointerEvents = 'auto';
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
