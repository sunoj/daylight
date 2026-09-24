import React, { useState, useEffect } from 'react';
import SettingToggle from './SettingToggle';
import { HTMLSelect, Tag, AppDialog, Button } from '@hackplan/uui';
import emitter from '../../lib/EventEmitter';
import { saveSetting } from '../../lib/utils';

export const defaultSettings = {
  'weekNumber': true,
  'recommendedAction': true,
  'lunarDay': true,
  'autoOpen': undefined,
  'darkMode': undefined,
  'doubleView': false,
  'calendarType': "ISO 8601"
}


const Settings = (props) => {
  const calendarTypeOptions = [{
    label: '国际标准',
    value: 'ISO 8601'
  }, {
    label: '美式',
    value: 'US'
  }, {
    label: '阿拉伯历',
    value: 'Arabic'
  }, {
    label: '希伯来历',
    value: 'Hebrew'
  }];
  const [calendarType, setCalendarType] = useState(props.settings.calendarType);

  const saveCalendarType = (calendarType) => {
    setCalendarType(calendarType)
    chrome.storage.sync.set({"calendarType": calendarType}, function() {
      emitter.emit('settingUpdate', props.storeKey);
    });
    chrome.runtime.sendMessage({action: "settingUpdate"}, function(response) {
      console.log(response);
    });
    saveSetting("calendarType", calendarType)
  }

  return (
    <div className={`settings ${props.className}`}>
      <div className="p-6">
      <h2 className="p-2 m-0">
        设置
        <span aria-label="返回主界面" data-microtip-position="left" role="tooltip" className="float-right cursor-pointer leading-4" onClick={props.onGoBack}>྾</span>
      </h2>
      <div className="setting-options min-h-full p-2 overflow-auto">
        <div className="option flex justify-between pb-2">
          <label aria-label="默认将跟随系统设置" data-microtip-position="bottom-right" role="tooltip" className="inline-block text-sm"><span className="w-5 inline-block text-center mr-2">🌚</span>暗夜模式</label>
          <SettingToggle className="inline-block w-12" title="暗夜模式" storeKey="darkMode" onChange={props.onSettingChange}/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm" aria-label="在月视图显示农历日期" data-microtip-position="top-right" role="tooltip"><span className="w-5 inline-block text-center mr-2">🌱</span>显示农历</label>
          <SettingToggle className="inline-block w-12" title="农历" storeKey="lunarDay" onChange={props.onSettingChange}/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm" aria-label="每天第一次打开自动显示当天详情" data-microtip-position="top-right" role="tooltip"><span className="w-5 inline-block text-center mr-2">🗓</span>每日详情</label>
          <SettingToggle className="inline-block w-12" title="每日详情" storeKey="autoOpen"/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm" aria-label="使用emoji表示的周几显示在浏览器图标位置" data-microtip-position="top-right" role="tooltip"><span className="w-5 inline-block text-center mr-2">👍</span>emoji 图标</label>
          <SettingToggle className="inline-block w-12" title="图标样式" storeKey="emojiIcon"/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm" aria-label="每天晚上8点之后浏览器图标将显示为当天的月相" data-microtip-position="top-right" role="tooltip"><span className="w-5 inline-block text-center mr-2">🌘</span>月相图</label>
          <SettingToggle className="inline-block w-12" title="月相图" storeKey="moonPhase"/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm" aria-label="在日期界面左侧显示日历周" data-microtip-position="top-right" role="tooltip"><span className="w-5 inline-block text-center mr-2">🔢</span>日历周</label>
          <SettingToggle className="inline-block w-12" title="日历周" storeKey="weekNumber" onChange={props.onSettingChange}/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm" aria-label="在日期详情页面显示没有科学依据的建议" data-microtip-position="top-right" role="tooltip">
            <span className="w-5 inline-block text-center mr-2">🙅</span>
            宜与不宜
          </label>
          <SettingToggle className="inline-block w-12" title="宜与不宜" storeKey="recommendedAction" onChange={props.onSettingChange}/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm" aria-label="在日历视图展示两个相邻月视图日历" data-microtip-position="top-right" role="tooltip">
            <span className="w-5 inline-block text-center mr-2">👨‍❤️‍👨</span>
            双日历视图
          </label>
          <SettingToggle className="inline-block w-12" title="双日历视图" storeKey="doubleView" onChange={props.onSettingChange}/>
        </div>

        <div className="option flex justify-between pb-2">
          <label className="inline-block text-sm cursor-pointer" aria-label="设置不同的日历类型可改变每周开始时间" data-microtip-position="top-right" role="tooltip" onClick={async () => {
            const result = await AppDialog(props => {
              return <>
                <div style={{
                  width: 400,
                  height: 300
                }}>
                  <h1 className="text-center text-sm" style={{ marginTop: 0 }}>不同日历类型的差别</h1>
                  <ul className="text-sm">
                    <li className="mb-2">
                      <Tag>国际标准</Tag>
                      <div  className="ml-6 text-xs">"ISO 8601"标准下的日历，每周的开始时间为周一，周末为周六和周日</div>
                    </li>
                    <li className="mb-2">
                      <Tag>美式</Tag>
                      <div className="ml-6 text-xs">美式标准下的日历，每周的开始时间为周日，周末为周六和周日</div>
                    </li>
                    <li className="mb-2">
                      <Tag>阿拉伯历</Tag>
                      <div className="ml-6 text-xs">阿拉伯历标准下，每周的开始时间为周六，周末为周五和周六</div>
                    </li>
                    <li>
                      <Tag>希伯来历</Tag>
                      <div className="ml-6 text-xs">希伯来历标准下，每周的开始时间为周日，周末为周五和周六</div>
                    </li>
                  </ul>
                </div>
                <div className="flex flex-row justify-end">
                  <Button onClick={() => { props.onCancel(); }}>
                    知道了
                  </Button>
                </div>
              </>;
            }, {
              cancelOnClickAway: true
            });
            console.log(result);
          }}>
            <span className="w-5 inline-block text-center mr-2">📅</span>
            日历类型
            <Tag className="transform info-icon">ℹ</Tag>
          </label>
          <HTMLSelect options={calendarTypeOptions} value={calendarType} onChange={value => {
            saveCalendarType(value);
          }} />
        </div>

      </div>
      </div>
    </div>
  );
}

export default Settings;