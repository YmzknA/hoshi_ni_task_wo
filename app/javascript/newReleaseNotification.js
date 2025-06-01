export function newReleaseNotification() {
  const newReleaseNotification= document.querySelector("#new_release_notification");
  const newReleaseClose= document.querySelector("#new_release_close");

  if (!newReleaseNotification) {
    console.log('addButtonNotification: id="new_release_notification"の要素が見つかりません');
    return;
  }

  if (newReleaseClose && newReleaseNotification) {
    newReleaseClose.addEventListener("click", function() {
      localStorage.setItem('newReleaseNotification', 'closed');
      newReleaseNotification.style.display = "none";
    });
  }

  const newReleaseNotificationClose = localStorage.getItem('newReleaseNotification');
  if (newReleaseNotificationClose === 'closed') {
    newReleaseNotification.style.display = "none";
  }else {
    newReleaseNotification.style.display = "flex";
  }
}

