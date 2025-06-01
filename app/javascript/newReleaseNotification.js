export function newReleaseNotification() {
  const newReleaseNotification= document.querySelector("#new_release_notification");
  const newReleaseClose= document.querySelector("#new_release_close");

  if (newReleaseClose && newReleaseNotification) {
    newReleaseClose.addEventListener("click", function() {
      localStorage.setItem('newReleaseNotification', 'closed');
      newReleaseNotification.style.display = "none";
    });
  }else{
    console.log('newReleaseNotification: id="new_release_notification または id="new_release_close"の要素が見つかりません');
  }

  if (!newReleaseNotification) {
    console.log('newReleaseNotification: id="new_release_notification"の要素が見つかりません');
    return;
  }

  const newReleaseNotificationClose = localStorage.getItem('newReleaseNotification');
  if (newReleaseNotificationClose === 'closed') {
    newReleaseNotification.style.display = "none";
  }else{
    newReleaseNotification.style.display = "flex";
  }
}

