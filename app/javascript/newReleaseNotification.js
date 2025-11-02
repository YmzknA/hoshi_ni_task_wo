export function newReleaseNotification() {
  const STORAGE_KEY = 'newReleaseNotification_11';
  const newReleaseNotification= document.querySelector("#new_release_notification");
  const newReleaseClose= document.querySelector("#new_release_close");

  if (!newReleaseNotification || !newReleaseClose) {
    return;
  }

  // 新しいリリース通知の閉じるボタンにクリックイベントを追加
  // クリックされたらローカルストレージに閉じたことを記録し、通知を非表示にする
  newReleaseClose.addEventListener("click", function() {
    localStorage.setItem(STORAGE_KEY, 'closed');
    newReleaseNotification.style.display = "none";
  });

  // ページ読み込み時にローカルストレージから通知の状態を確認し、表示を制御する
  const newReleaseNotificationClose = localStorage.getItem(STORAGE_KEY);
  if (newReleaseNotificationClose === 'closed') {
    newReleaseNotification.style.display = "none";
  }else{
    newReleaseNotification.style.display = "flex";
  }
}

