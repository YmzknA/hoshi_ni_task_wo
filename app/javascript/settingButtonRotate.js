export function settingButtonRotate() {
  const settingsButton = document.getElementById('setting_button');
  const settingMark= document.getElementById('setting_mark');

  if (settingsButton && settingMark) {
    settingsButton.addEventListener('mouseover', () => {
      settingMark.classList.add('rotate-[360deg]', 'transition-transform', 'duration-300');
      setTimeout(() => {
        settingMark.classList.remove('rotate-[360deg]', 'transition-transform', 'duration-300');
      }, 300);
      return;
    });
  }
}
