import React, { useState } from 'react';
import { Drawer, Tag } from '@hackplan/uui';


const changelog = [
  {
    version: "0.2.5",
    date: "2021年11月29日",
    batch: "beta",
    detail: "修复24节气算法在一些边缘情况的问题（冬至无法显示）；"
  },
  {
    version: "0.2.4",
    date: "2020年11月18日",
    batch: "beta",
    detail: "改进24节气算法；解决开启浏览器放大功能同时开启双日历视图时，界面完整的问题；"
  },
  {
    version: "0.2.3",
    date: "2020年9月6日",
    batch: "beta",
    detail: "修复浏览器图标标题栏的农历显示"
  },
  {
    version: "0.2.2",
    date: "2020年8月29日",
    batch: "beta",
    detail: "优化暗夜模式的判断算法；改善样式；"
  },
  {
    version: "0.2.1",
    date: "2020年8月29日",
    batch: "beta",
    detail: "更换天文算法来计算二十四节气以避免误差"
  },
  {
    version: "0.2.0",
    date: "2020年6月14日",
    batch: "beta",
    detail: "增加多种日历类型的设置；增加双日历视图的设置；改善缓存；"
  },
  {
    version: "0.1.10",
    date: "2020年6月10日",
    batch: "beta",
    detail: "优化暗夜模式的加载和保存；修复一些样式；"
  },
  {
    version: "0.1.9",
    date: "2020年5月27日",
    batch: "beta",
    detail: "修复设置在浏览器重启后被恢复的问题；修复日记编辑功能；修复一些样式；"
  },
  {
    version: "0.1.7",
    date: "2020年5月24日",
    batch: "beta",
    detail: "修复设置问题；改善暗黑模式下的样式；"
  },
  {
    version: "0.1.6",
    date: "2020年5月10日",
    batch: "beta",
    detail: "升级 ui 库，解决一些细节问题"
  },
  {
    version: "0.1.2",
    date: "2020年4月29日",
    batch: "beta",
    detail: "优化初次加载的体验，改善 Firefox 下的样式"
  },
  {
    version: "0.0.1",
    date: "2020年4月27日",
    batch: "beta",
    detail: "如有问题，欢迎写邮件至：<hi@mings.work>"
  }
]


const About = (props) => {
  const [showTab, setShowTab] = useState('about');
  return (
    <Drawer
      placement="bottom"
      active={props.open}
      onDismiss={props.onDismiss}
      customize={
        {
          Content: {
            extendClassName: "mb-8"
          }
        }
      }
    >
      <div className="p-2 h-64">
        <div className="flex list-none text-center m-0 my-0 mx-auto w-2/3">
          <div className="flex-1 mr-2">
            <span className={`cursor-pointer text-xs text-center block ${showTab == 'about' ? "border-blue-500 bg-blue-500 hover:bg-blue-700 text-white": "hover:border-gray-200 text-blue-500 hover:bg-gray-300"} rounded py-2 px-4`} onClick={() => setShowTab('about')}>关于昼间</span>
          </div>
          <div className="flex-1 mr-2">
            <span className={`cursor-pointer text-xs text-center block rounded ${showTab == 'faq' ? "border-blue-500 bg-blue-500 hover:bg-blue-700 text-white": "hover:border-gray-200 text-blue-500 hover:bg-gray-300"} py-2 px-4`} onClick={() => setShowTab('faq')}>常见问题</span>
          </div>
          <div className="flex-1 mr-2">
            <span className={`cursor-pointer text-xs text-center block rounded ${showTab == 'changelog' ? "border-blue-500 bg-blue-500 hover:bg-blue-700 text-white": "hover:border-gray-200 text-blue-500 hover:bg-gray-300"} py-2 px-4`} onClick={() => setShowTab('changelog')}>最近更新</span>
          </div>
        </div>
        <ul className={showTab == 'faq' ? "leading-8 text-xs overflow-y-auto h-56" : "hidden"}>
          <li>
            <p>Q: 每周开始时间能改吗？</p>
            <p>A: 可以在设置中更改“日历类型”来控制每周开始时间。</p>
          </li>
          <li>
            <p>Q: 昼间如何储存数据</p>
            <p>A: 用户在昼间创建的日期标记和日记将只储存在本地数据库</p>
          </li>
          <li>
            <p>Q: 日历信息如何提供</p>
            <p>A: 假期等公共日历信息由一个公开数据库提供，农历/节气/月相等信息均为本地算法计算</p>
          </li>
        </ul>

        <div className={showTab == 'about' ? "leading-7 text-xs" : "hidden"}>
          <p>昼间的诞生离不开以下这些开源软件：</p>
          <ul className="">
            <li> <a href="https://github.com/wojtekmaj/react-calendar" target="_blank">react-calendar</a> </li>
            <li> <a href="https://github.com/mourner/suncalc" target="_blank">suncalc</a> </li>
            <li> <a href="https://uui.cool/" target="_blank">uui</a> </li>
            <li> <a href="https://microtip.now.sh/" target="_blank">microtip</a> </li>
            <li> <a href="https://github.com/facebook/react" target="_blank">react</a> </li>
          </ul>
        </div>

        <div className={showTab == 'changelog' ? "leading-7 text-xs overflow-y-auto h-56" : "hidden"}>
          <ul className="">
            {
              changelog.map((change) => {
                return (
                  <li key={change.version}>
                    <div>
                      <span aria-label={change.date} data-microtip-position="right" role="tooltip">{change.version}</span>
                      {change.batch == 'beta' && <Tag className="transform scale-75 text-xs">体验版</Tag>}
                    </div>
                    <div>{change.detail}</div>
                  </li>
                )
              })
            }
          </ul>
        </div>
      </div>
    </Drawer>
  );
};

export default About;
