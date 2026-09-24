import React, { useState, useEffect, useMemo } from 'react';
import { DateTime } from 'luxon';
import PouchDB from 'pouchdb';
import ReactCardFlip from 'react-card-flip';
import { Dialog, DateLabel, TextArea, Button, Toaster, ToasterPosition } from '@hackplan/uui';
import emitter from '../../lib/EventEmitter';

import { solarToLunar } from '../../lib/SolarToLunar';

import RecommendedAction from './RecommendAction';
import DateMark from './DateMark';

const localDB_diary = new PouchDB('diary')
const AppToaster = Toaster.create({
  maxToasts: 3,
  position: ToasterPosition.TopRight,
})

const DateDetail = (props) => {
  const { currentDay, opened, currentDayDetail, currentDayMark } = props
  const [isFlipped, setIsFlipped] = useState(false);
  const [text, setText] = useState(null);
  const [diary, setDiary] = useState(null);

  const dateLunarDetail = solarToLunar(currentDay)
  const todayISO = useMemo(() => DateTime.fromJSDate(currentDay).toFormat('y-M-d'), [currentDay])

  const updateDiary = () => {
    localDB_diary.put({
      _id: `diary:${todayISO}`,
      ...(diary ? { _rev: diary._rev } : {}),
      content: text
    }, {
      force: true
    }).then(function () {
      setDiary({
        ...diary,
        content:text
      })
      AppToaster.show({
        timeout: 1000,
        message: `日志已保存`,
      })
    }).catch((err) => {
      console.log(err);
    })
  }

  useEffect(() => {
    localDB_diary.get(`diary:${todayISO}`).then(function (doc: any) {
      setDiary(doc)
      if (doc.content) {
        setText(doc.content)
      }
    }).catch((err) => {
      setDiary(null)
      console.log(err);
    })
  }, [currentDay])

  const onHotKey = (message) => {
    switch (message) {
      case 'closeDialog':
        if (props.onClose) props.onClose()
        break;
      case 'Flip':
        setIsFlipped(isFlipped => !isFlipped)
        break;
      default:
        break;
    }
  }

  useEffect(() => {
    emitter.addListener('hotkey', onHotKey);
    return () => {
      emitter.removeListener('hotkey', onHotKey);
    }
  }, [])

  return (
    <Dialog className="w-32" open={opened} focusTrap={true} onClickAway={() => {
      if (props.onClose) props.onClose()
    }} customize={
      {
        Container: {
          extendClassName: `relative date-detail ${currentDayDetail.background_image ? 'imageBackground' : ''}`,
          extendStyle: { minHeight: "18em" }
        }
      }
    }>
      <div >
        {
          currentDayDetail.background_image && <div className="w-full h-full absolute top-0 left-0 rounded" style={
            {
              backgroundImage: `url(${currentDayDetail.background_image})`,
              backgroundSize: "cover",
              color: " #fff"
            }
          }></div>
        }
        <div className="corner" onClick={() => setIsFlipped(!isFlipped)}></div>
        <ReactCardFlip isFlipped={isFlipped} flipDirection="horizontal">
          <div className="detail">
            <div className="flex flex-col justify-around w-64 min-h-64">
              <div className="flex justify-between p-1 leading-tight align-middle">
                <div className="p-2">
                  {diary && diary.content && <button aria-label={diary.content} data-microtip-position="top" role="tooltip" className="leading-4" onClick={() => setIsFlipped(true)}>📃</button>}
                </div>
                <div className="flex-none p-2">
                  <DateLabel value={currentDay} locale={'zh-CN'} kind={'二○一二年三月'}></DateLabel>
                  <DateLabel className="ml-2" value={currentDay} locale={'zh-CN'} kind={'周三'}></DateLabel>
                </div>
                <div aria-label="关闭" data-microtip-position="top" role="tooltip" className="leading-4 p-2 cursor-pointer close-icon" onClick={props.onClose}>&times;</div>
              </div>
              <div className="big-date text-center p-2 relative pb-6">
                <div className="text-5xl">{currentDay.getDate()}</div>
                {
                  currentDayDetail && <div aria-label={currentDayDetail.description} data-microtip-position="top" role="tooltip" className="p-2">
                    {
                      currentDayDetail.name ? currentDayDetail.url ? <a className="text-sm date-name" href={currentDayDetail.url} target="_blank" style={currentDayDetail.style}>{currentDayDetail.name}</a> : <div className="text-sm date-name">{currentDayDetail.name}</div> :
                        <div className={`text-xs date-name ${currentDayDetail.type}`}>{currentDayDetail.belong_to}{currentDayDetail.type == 'holiday' ? '放假' : ''}{currentDayDetail.type == 'workday' ? '调休' : ''}</div>
                    }
                  </div>
                }
                {
                  dateLunarDetail && <div className="p-2">
                    <div className="text-xs">{dateLunarDetail.lunarYear}年 {dateLunarDetail.lunarMonth}月{dateLunarDetail.lunarDay} {dateLunarDetail.solarTerm}</div>
                  </div>
                }
                <DateMark className="text-sm" date={currentDay} mark={currentDayMark} onChange={() => {
                  if (props.onMarkChange) props.onMarkChange(currentDay)
                }} />
              </div>
              {props.showRecommendedAction && props.recommendedActions && <RecommendedAction date={currentDay} recommendedActions={props.recommendedActions} />}
            </div>
          </div>

          <div className="h-64 w-64">
            <div className="flex justify-between align-middle">
              <DateLabel className="leading-4 py-2" value={currentDay} locale={'zh-CN'} kind={'2012年3月14日'}></DateLabel>
              <button aria-label="返回日期" data-microtip-position="top" role="tooltip" className="cursor-pointer leading-4 p-2 close-icon" onClick={() => setIsFlipped(false)}>&times;</button>
            </div>
            <TextArea value={text} onChange={value => { setText(value); }} placeholder={'请输入...'} />
            <Button className="w-full mt-2" onClick={() => {
              updateDiary();
            }}>保存</Button>
          </div>
        </ReactCardFlip>
      </div>
    </Dialog>
  )
};

export default DateDetail;