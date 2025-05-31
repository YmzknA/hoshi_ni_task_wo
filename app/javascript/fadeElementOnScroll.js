export function fadeElementOnScroll(id) {
  // 前回のスクロール位置を記録
  let lastScrollY = window.scrollY;

  // どれだけスクロールしたら反応するか(px)
  const scrollThreshold = 100;

  // 対象の要素を取得
  const targetItem = document.getElementById(id);


  // ボタンが存在しない場合は処理を終了
  if (!targetItem) {
    console.log('対象の要素が見つかりません');
    return;
  }

  // 初期スタイルを設定
  targetItem.style.transition = 'opacity 0.3s ease-in-out, transform 0.3s ease-in-out';

  // スクロールを検出する関数
  function handleScroll() {
    // 現在のスクロール位置を取得
    const currentScrollY = window.scrollY;

    // スクロール量の差を計算
    const scrollDiff = currentScrollY - lastScrollY;

    // 閾値以上のスクロールがあった場合のみ処理を実行
    if (Math.abs(scrollDiff) > scrollThreshold) {

      if (scrollDiff > 0) {
        // 非表示にする
        targetItem.style.opacity = '0';
        targetItem.style.transform = 'translateY(-5px)';
        targetItem.style.pointerEvents = 'none';

      } else {
        // 表示する
        targetItem.style.opacity = '1';
        targetItem.style.transform = 'translateY(0)';
        targetItem.style.pointerEvents = 'auto';
      }

      // 前回のスクロール位置を更新
      lastScrollY = currentScrollY;
    }
  }

  // 一回処理が終わるまで新たに処理をしないようにするフラグ
  let actionWait = false;

  function requestScrollUpdate() {
    if (!actionWait) {
      requestAnimationFrame(function() {
        handleScroll();
        actionWait = false;
      });
      actionWait = true;
    }
  }

  // スクロールをリッスン
  window.addEventListener('scroll', requestScrollUpdate, { passive: true });
}

