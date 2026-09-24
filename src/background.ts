import * as SunCalc from 'suncalc';

import { solarToLunar } from './lib/SolarToLunar';
import MoonPainter from './lib/MoonPainter';
import { DateTime } from 'luxon';


const weekdayMap = [
  {
    zh: '日',
    emoji: "✊"
  },
  {
    zh: '一',
    emoji: "👍"
  },
  {
    zh: '二',
    emoji: "✌️"
  },
  {
    zh: '三',
    emoji: "👌"
  },
  {
    zh: '四',
    emoji: "🖖"
  },
  {
    zh: '五',
    emoji: "🖐️"
  },
  {
    zh: '六',
    emoji: "🤙"
  }
]

const drawIcon = (settings: {
  emojiIcon?: boolean
  moonPhase?: boolean
}) => {
  let canvas = document.createElement('canvas'); // Create the canvas
  canvas.width = 32;
  canvas.height = 32;

  let context = canvas.getContext('2d');

  let iconBackgroundStyle = "#222";
  let iconTextStyle = "#222";

  if (context) {

    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      iconBackgroundStyle = "#eee";
      iconTextStyle = "#FFFFFF";
    }
    const date = new Date().getDate()
    const month = new Date().getMonth() + 1
    const weekday = new Date().getDay()

    context.textAlign = "center";
    context.textBaseline = "middle";
    if (settings.emojiIcon) {
      context.font = "24px Arial";
      context.fillText(weekdayMap[weekday].emoji, 16, 20);
    } else {
      context.fillStyle = iconBackgroundStyle
      context.fillRect(0, 0, 32, 32);
      context.clearRect(2, 8, 28, 22);
      context.font = "22px Arial";
      context.fillStyle = iconTextStyle
      context.fillText(String(date), 15, 21);
    }

    const lunarDetail = solarToLunar(DateTime.local().startOf("day").toJSDate())
    let iconTitle = `${month}月${date}日 星期${weekdayMap[weekday].zh} 农历${lunarDetail.lunarMonth}月${lunarDetail.lunarDay}${lunarDetail.solarTerm ? `(${lunarDetail.solarTerm})` : ''}`
    // 开启月相图 且 已日落
    if (settings.moonPhase && (new Date().getHours() >= 20 || new Date().getHours() < 5)) {
      let moon = SunCalc.getMoonIllumination(new Date())

      let painter = new MoonPainter(canvas);

      let moonStatus = '新月'
      switch (true) {
        case moon.phase > 0.25 && moon.phase < 0.5:
          moonStatus = '上弦月 🌓'
          break;
        case moon.phase > 0.5 && moon.phase < 0.75:
          moonStatus = '满月 🌕'
          break;
        case moon.phase > 0.75:
          moonStatus = '下弦月 🌗'
          break;
        default:
          break;
      }

      iconTitle = `${moonStatus} ${iconTitle}`
      painter.paint(moon.phase);
    }


    chrome.browserAction.setTitle({
      title: iconTitle
    })

    chrome.browserAction.setIcon({
      imageData: canvas.getContext('2d').getImageData(0, 0, 32, 32)
    });
  }
};

const draw = () => {
  chrome.storage.sync.get(['emojiIcon', 'moonPhase'], function (settings) {
    if (settings) {
      drawIcon(settings)
    } else {
      drawIcon({
        'emojiIcon': false,
        'moonPhase': false
      })
    }
  });
}

// 监听事件以及时更新图标
chrome.runtime.onMessage.addListener(
  function (request, sender, sendResponse) {
    if (request.action == "settingUpdate") {
      draw()
    }
    sendResponse({ result: "Roger that" });
  });


// 定时任务
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name == 'cycleTask') {
    draw();
  }
  if (alarm.name == 'reload') {
    chrome.runtime.reload()
    chrome.alarms.clearAll()
  }
})

// 每600分钟完全重载
chrome.alarms.create('reload', { periodInMinutes: 600 })

// 每10分钟定时刷新 icon
chrome.alarms.create('cycleTask', {
  when: 1000,
  periodInMinutes: 10
});
