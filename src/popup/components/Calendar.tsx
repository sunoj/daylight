import React, { useMemo, useState, useEffect, useCallback } from 'react';
import Calendar from 'react-calendar';
import { DateTime } from 'luxon';
import PouchDB from 'pouchdb';

import { solarToLunar } from '../../lib/SolarToLunar';
import emitter from '../../lib/EventEmitter';
import DateDetail from './DateDetail';
import { getKeyByDateType } from './DateMark';
import { getSetting, saveSetting } from '../../lib/utils';

const localDB_publicCalendar = new PouchDB('public-calendar')
const localDB_recommendedAction = new PouchDB('recommended-action')
const localDB_mark = new PouchDB('mark')

interface ICalendarProps {
  view: "month" | "year" | "decade" | "century"
  activeStartDate?: Date
  settings: {
    [key: string]: any;
  }
  onActiveStartDateChange?: (props) => void
  onViewChange?: (props) => void
}

let DateDetailCache = {}
let DateMarkCache = {}

const CalendarView = (props: ICalendarProps) => {
  const [opened, setOpened] = useState(false);
  const [publicCalendar, setPublicCalendar] = useState()
  const [recommendedActions, setRecommendedAction] = useState()
  const [marks, setMarks] = useState()
  const [currentDay, setCurrentDay] = useState<Date>(new Date());

  // 查询日期详情
  const getDateDetail = (date: Date) => {
    const dateISO = DateTime.fromJSDate(date).toFormat('y-M-d')
    if (DateDetailCache[dateISO]) return DateDetailCache[dateISO]
    if (publicCalendar) {
      const dateDetail: any = publicCalendar.find((e: any) => e.key == dateISO)
      if (!dateDetail) return false
      DateDetailCache[dateISO] = dateDetail.doc
      return dateDetail.doc
    }
    return false
  }

  // 查询日期标记
  const getDateMark = (date: Date) => {
    const dateISO = DateTime.fromJSDate(date).toFormat('y-M-d')
    if (DateMarkCache[dateISO]) return DateMarkCache[dateISO]
    if (!marks) return null
    const dateMarks = {};
    ["yearly", "monthly", "onetime"].map((type) => {
      const key = getKeyByDateType(date, type)
      const mark: any = marks.find((e: any) => e.key == key)
      if (mark && mark.doc) {
        dateMarks[type] = mark.doc
      }
    })
    if (Object.keys(dateMarks).length === 0) return null
    DateMarkCache[dateISO] = dateMarks
    return dateMarks
  }

  const dateRender = ({ date, view }) => {
    if (view != 'month') return null
    const dateDetail: any = getDateDetail(date)
    const dateMarks: any = getDateMark(date)
    const dateLunarDetail = withLunarDay ? solarToLunar(date) : null
    return (
      <span className="date-item flex justify-center" style={{
        width: "150%",
        marginLeft: "-25%"
      }}>
        {dateDetail.type == 'holiday' && <span className="special-tag public-holiday">假</span>}
        {dateDetail.type == 'workday' && <span className="special-tag public-workday">班</span>}
        {dateDetail.name && dateDetail.important && <span className="text-xs block date-name">{dateDetail.name}</span>}
        {(!(dateDetail.name && dateDetail.important) && dateLunarDetail) && <span className="text-xs block date-name">{dateLunarDetail.solarTerm ? dateLunarDetail.solarTerm : `${dateLunarDetail.lunarDay}`}</span>}
        {dateMarks && <span>
          {dateMarks.yearly && <div className="mark yearly"></div>}
          {dateMarks.monthly && <div className="mark monthly"></div>}
          {dateMarks.onetime && <div className="mark onetime"></div>}
          <span className="mark-detail speech-bubble">
            {dateMarks.yearly && <span> {dateMarks.yearly.content} </span>}
            {dateMarks.monthly && <span> {dateMarks.monthly.content} </span>}
            {dateMarks.onetime && <span> {dateMarks.onetime.content} </span>}
          </span>
        </span>
        }
      </span>
    )
  }

  const onHotKey = (message) => {
    switch (message) {
      case 'closeDialog':
        setOpened(false)
        break;
      case 'dateDetail':
        setOpened(true)
        break;
      case 'prevDay':
        setCurrentDay(currentDay => DateTime.fromJSDate(currentDay).minus({ 'day': 1 }).toJSDate())
        break;
      case 'nextDay':
        setCurrentDay(currentDay => DateTime.fromJSDate(currentDay).plus({ 'day': 1 }).toJSDate())
        break;
      default:
        break;
    }
  }

  const loadDataFormDB = (specified?: string) => {
    if (!specified || specified == 'public-calendar') {
      localDB_publicCalendar.allDocs({
        include_docs: true,
        attachments: false
      }).then(function (result) {
        setPublicCalendar(result.rows);
      })
    }
    if (!specified || specified == 'recommended-action') {
      localDB_recommendedAction.allDocs({
        include_docs: true,
        attachments: false
      }).then(function (result) {
        setRecommendedAction(result.rows);
      })
    }
    if (!specified || specified == 'mark') {
      localDB_mark.allDocs({
        include_docs: true,
        attachments: false
      }).then(function (result) {
        setMarks(result.rows);
      })
    }
  }


  useEffect(() => {
    loadDataFormDB()
    // 接收消息
    chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
      switch (message.action) {
        case "cloudDBUpdated":
          loadDataFormDB(message.dbName)
          break;
        default:
          break;
      }
      sendResponse("Calendar Roger that")
    });
    emitter.addListener('hotkey', onHotKey);
    return () => {
      emitter.removeListener('hotkey', onHotKey);
    }
  }, [])


  useEffect(() => {
    const lastSyncDataComplete = getSetting('lastSyncDataComplete', null)
    if (lastSyncDataComplete) {
      const todayISO = DateTime.local().toISODate();
      if (props.settings && props.settings.autoOpen && getSetting('lastAutoOpen', false) != todayISO) {
        setTimeout(() => {
          setOpened(true)
          saveSetting('lastAutoOpen', todayISO)
        }, 250);
      }
    }
  }, [props.settings])

  const currentDayDetail = useMemo(() => getDateDetail(currentDay), [currentDay])
  const currentDayMark = useMemo(() => getDateMark(currentDay), [currentDay, marks])

  const withLunarDay = useMemo(() => props.settings && props.settings.lunarDay, [props.settings]);

  return (
    <div className="calendar" style={{
      width: props.settings.doubleView ? "800px" : "460px"
    }}>
      <Calendar
        className={withLunarDay ? "withLunarDay" : ""}
        view={props.view}
        showDoubleView={props.settings.doubleView}
        calendarType={props.settings.calendarType}
        onViewChange={props.onViewChange}
        activeStartDate={props.activeStartDate}
        onActiveStartDateChange={props.onActiveStartDateChange}
        onChange={(date: Date) => setCurrentDay(date)}
        value={currentDay}
        showWeekNumbers={props.settings.weekNumber}
        tileContent={dateRender}
        onClickDay={(date: Date) => {
          setCurrentDay(date)
          setOpened(true)
        }}
        formatLongDate={() => null}
        showFixedNumberOfWeeks={true}
      />
      {
        opened &&
        <DateDetail
          opened={opened}
          currentDayDetail={currentDayDetail}
          currentDayMark={currentDayMark}
          currentDay={currentDay}
          onClose={() => { setOpened(false) }}
          onMarkChange={(date) => {
            localDB_mark.allDocs({
              include_docs: true,
              attachments: false
            }).then(function (result) {
              setMarks(result.rows);
              DateMarkCache[DateTime.fromJSDate(date).toFormat('y-M-d')] = undefined;
            })
          }}
          showRecommendedAction={props.settings && props.settings.recommendedAction}
          recommendedActions={recommendedActions} />
      }
    </div>
  );
}

export default CalendarView;