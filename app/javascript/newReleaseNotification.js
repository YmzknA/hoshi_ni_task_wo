export function newReleaseNotification() {
  const newReleaseNotification= document.querySelector("#new_release_notification");
  const newReleaseClose= document.querySelector("#new_release_close");

  if (!newReleaseNotification || !newReleaseClose) {
    console.log('newReleaseNotification: id="new_release_notification または id="new_release_close"の要素が見つかりません');
    return;
  }

  // 新しいリリース通知の閉じるボタンにクリックイベントを追加
  // クリックされたらローカルストレージに閉じたことを記録し、通知を非表示にする
  newReleaseClose.addEventListener("click", function() {
    localStorage.setItem('newReleaseNotification', 'closed');
    newReleaseNotification.style.display = "none";
  });

  // ページ読み込み時にローカルストレージから通知の状態を確認し、表示を制御する
  const newReleaseNotificationClose = localStorage.getItem('newReleaseNotification');
  if (newReleaseNotificationClose === 'closed') {
    newReleaseNotification.style.display = "none";
  }else{
    newReleaseNotification.style.display = "flex";
  }
}

