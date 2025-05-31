export function addButtonNotification() {
  const add_button_notification = document.querySelector("#add_button_notification");
  const add_button_notification_close = document.querySelector("#add_button_notification_close");

  if (!add_button_notification) {
    console.log('addButtonNotification: id="add_button_notification"の要素が見つかりません');
    return;
  }

  if (add_button_notification_close) {
    add_button_notification_close.addEventListener("click", function() {
    console.log("add_button_notification is closed");
      localStorage.setItem('add_button_notification', 'closed');
      add_button_notification.style.display = "none";
    });
  }

  const add_button_notification_closed = localStorage.getItem('add_button_notification')
  if (add_button_notification_closed === 'closed') {
    add_button_notification.style.display = "none";
  }else {
    add_button_notification.style.display = "flex";
  }
}
