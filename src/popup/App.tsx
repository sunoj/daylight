import React, { useState, useEffect, useMemo } from 'react';
import { DateTime } from 'luxon';

import './App.css';

import ReactCardFlip from 'react-card-flip';
import { getApplicationKeyMap, KeyMap, GlobalHotKeys } from "react-hotkeys";

import { getSetting, getSettingsWithDefault } from '../lib/utils';
import emitter from '../lib/EventEmitter';

import CalendarView from './components/Calendar';
import Settings, { defaultSettings } from './components/Settings';
import HotKeyMap from './components/HotKeyMap';
import About from './components/About';
import Vitamin from './components/Vitamin';

const keyMap: KeyMap = {
  Prev: {
    name: '上一天',
    sequences: ["left"],
    sequence: "left",
    action: 'keyup'
  },
  Next: {
    name: '下一天',
    sequences: ["right"],
    sequence: "right",
    action: 'keyup'
  },
  Up: {
    name: '上个月',
    sequences: ["up"],
    sequence: "up",
    action: 'keyup'
  },
  Down: {
    name: '下个月',
    sequences: ["down"],
    sequence: "down",
    action: 'keyup'
  },
  CLOSE_DIALOG: {
    name: '关闭弹窗',
    sequence: "w",
    action: 'keyup'
  },
  Detail: {
    name: '打开日期详情',
    sequence: "d",
    action: 'keyup'
  },
  BACK_TODAY: {
    name: '回到当前月份',
    sequences: ["m", "o"],
    sequence: "m",
    action: 'keyup'
  },
  HOTKEY_MAP: {
    name: '显示快捷键提示',
    sequences: ["h", "shift+?"],
    sequence: "h",
    action: 'keyup'
  },
  SETTING: {
    name: '进入设置页面',
    sequences: ["s", "c"],
    sequence: "s",
    action: 'keyup'
  }
  ,
  Flip: {
    name: '翻转界面',
    sequences: ["f"],
    sequence: "f",
    action: 'keyup'
  }
};

function App() {
  const firstDayOfCurrentMonth = DateTime.local().startOf('month').toJSDate();
  const [firstLoad, setFirstLoad] = useState(true)
  const [isFlipped, setIsFlipped] = useState(false)
  const [infoActive, setInfoActive] = useState(false)
  const [hotKeyMapOpened, setHotKeyMapOpened] = useState(false)
  const [activeStartDate, setActiveStartDate] = useState(firstDayOfCurrentMonth)

  const [view, setView] = useState<"month" | "year" | "decade" | "century">('month')
  const [settings, setSettings] = useState<{
    [key: string]: any;
  }>(getSettingsWithDefault(defaultSettings))


  const getSettingFromStorage = () => {
    const result = getSettingsWithDefault(defaultSettings)
    setSettings(result);
    if (result.darkMode) {
      document.body.classList.remove("light-mode")
      document.body.classList.add("dark-mode")
    } else if (typeof result.darkMode != "undefined") {
      document.body.classList.remove("dark-mode")
      document.body.classList.add("light-mode")
      document.documentElement.style.background = null
    }
  }

  useEffect(() => {
    getSettingFromStorage()
    // 接收消息
    chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
      switch (message.action) {
        case "settingUpdate":
          getSettingFromStorage()
          break;
        default:
          break;
      }
      console.log('calendar onMessage', message)
      sendResponse("App Roger that")
    });

    setTimeout(() => {
      setFirstLoad(false)
    }, 250);

    emitter.on("settingUpdate", () => {
      getSettingFromStorage()
    })
  }, []);

  const goDate = (date: Date) => {
    setIsFlipped(false);
    setActiveStartDate(date);
    setView('month')
  }

  const onCurrentMonth = useMemo(() => !isFlipped && DateTime.local().hasSame(DateTime.fromJSDate(activeStartDate), 'month') && view == 'month', [isFlipped, activeStartDate, view]);

  const handlers = {
    HOTKEY_MAP: () => {
      setHotKeyMapOpened(true)
    },
    CLOSE_DIALOG: () => {
      setHotKeyMapOpened(false)
      emitter.emit('hotkey', 'closeDialog');
    },
    Detail: () => {
      emitter.emit('hotkey', 'dateDetail');
    },
    BACK_TODAY: () => {
      goDate(firstDayOfCurrentMonth)
    },
    SETTING: () => {
      setIsFlipped(true)
    },
    Flip: () => {
      emitter.emit('hotkey', 'Flip');
    },
    Up: () => {
      const prevMonth = DateTime.fromJSDate(activeStartDate).minus({ 'month': 1 }).startOf('month').toJSDate()
      return goDate(prevMonth)
    },
    Down: () => {
      const nextMonth = DateTime.fromJSDate(activeStartDate).plus({ 'month': 1 }).startOf('month').toJSDate()
      return goDate(nextMonth)
    },
    Prev: () => {
      emitter.emit('hotkey', 'prevDay');
    },
    Next: () => {
      emitter.emit('hotkey', 'nextDay');
    }
  }

  return (
    <div className={settings.darkMode ? "dark-mode" : ""}>
      <div className="App pb-8">
        <GlobalHotKeys keyMap={keyMap} handlers={handlers} allowChanges={true} />
        {settings &&
          <ReactCardFlip isFlipped={isFlipped} flipDirection="horizontal" flipSpeedBackToFront={0.5} flipSpeedFrontToBack={0.5}>
            <CalendarView
              view={view}
              activeStartDate={activeStartDate}
              settings={settings}
              onActiveStartDateChange={({ activeStartDate }) => setActiveStartDate(activeStartDate)}
              onViewChange={({ view }) => setView(view)}
            />
            <Settings settings={settings} className={firstLoad ? "hidden" : ""} onGoBack={() => { setIsFlipped(false) }} onSettingChange={(updatedSettings) => setSettings(Object.assign({}, settings, updatedSettings))} />
          </ReactCardFlip>
        }
        <About open={infoActive} onDismiss={() => {
          setInfoActive(false)
        }}></About>
        <div className="bottom fixed bottom-0 w-full flex content-between items-center">
          <div aria-label="设置" data-microtip-position="top-right" role="tooltip">
            <button className="action-icon" onClick={() => { setIsFlipped(!isFlipped) }}>⚙</button>
          </div>
          {
            !onCurrentMonth && <div aria-label="回到本月" data-microtip-position="top" role="tooltip">
              <button className="action-icon" onClick={() => goDate(firstDayOfCurrentMonth)}>⊙</button>
            </div>
          }
          {
            onCurrentMonth && <Vitamin />
          }
          <div aria-label="关于昼间" data-microtip-position="top-left" role="tooltip">
            <button className="action-icon" onClick={() => { setInfoActive((value => !value)) }}>ℹ</button>
          </div>
        </div>
        <HotKeyMap open={hotKeyMapOpened} keyMap={getApplicationKeyMap()} onClose={() => setHotKeyMapOpened(false)} />
      </div>
    </div>
  );
}

export default App;
