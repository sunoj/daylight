var isDarkModeEnabled = window.matchMedia('(prefers-color-scheme: dark)').matches;
if (localStorage.getItem("darkMode")) {
  isDarkModeEnabled = localStorage.getItem("darkMode") == 'true'
}
if (isDarkModeEnabled) {
  document.documentElement.style.background = "#1a1919"
}

document.addEventListener("DOMContentLoaded", function(){
  if (isDarkModeEnabled) {
    document.body.classList.add('dark-mode')
  } else {
    document.body.classList.add('light-mode')
  }
})

// 防止缩放
chrome.tabs.getZoomSettings((zoomSettings) => {
  if (zoomSettings.defaultZoomFactor > 1 && zoomSettings.scope == 'per-origin' && zoomSettings.mode == 'automatic' && localStorage.getItem("doubleView") == 'true') {
    let zoomPercent = (100 / (zoomSettings.defaultZoomFactor * 100)) * 100;
    document.body.style.zoom = zoomPercent + '%'
    document.body.style.setProperty("--zoom-factor", zoomSettings.defaultZoomFactor);
  }
})