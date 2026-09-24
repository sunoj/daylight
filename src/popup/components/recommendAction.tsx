import React, { useMemo, useState } from 'react';
import { DateTime } from 'luxon';
import { getSetting, saveSetting } from '../../lib/utils';

let dateRecommendedActionCache = getSetting('dateRecommendedActionCache', {})

const RecommendedAction = (props) => {
  const getRecommendedAction = (date) => {
    const dateISO = DateTime.fromJSDate(date).toFormat('y-M-d')
    if (dateRecommendedActionCache[dateISO]) return dateRecommendedActionCache[dateISO]
    let goodAction: any = props.recommendedActions.find((e: any) => e.key == `good:${dateISO}`)
    let badAction: any = props.recommendedActions.find((e: any) => e.key == `bad:${dateISO}`)
    let commonGoodAction: any = props.recommendedActions.find((e: any) => e.key == `good:common`)
    let commonBadAction: any = props.recommendedActions.find((e: any) => e.key == `bad:common`)
    if (goodAction) {
      goodAction = goodAction.doc.list[Math.floor(Math.random() * goodAction.doc.list.length)]
    } else if (commonGoodAction) {
      let actionList = commonGoodAction.doc.base
      if (commonGoodAction.doc.weekend && (props.date.getDay() == 1 || props.date.getDay() == 6)) {
        actionList = commonGoodAction.doc.weekend
      }
      goodAction = actionList[Math.floor(Math.random() * actionList.length)]
    }
    if (badAction) {
      badAction = badAction.doc
    } else if (commonBadAction) {
      let actionList = commonBadAction.doc.base
      if (commonBadAction.doc.weekend && (props.date.getDay() == 1 || props.date.getDay() == 6)) {
        actionList = commonBadAction.doc.weekend
      }
      badAction = actionList[Math.floor(Math.random() * actionList.length)]
    }
    dateRecommendedActionCache[dateISO] = {goodAction, badAction}

    if (Object.keys(dateRecommendedActionCache).length > 100) {
      saveSetting('dateRecommendedActionCache', {})
    } else {
      saveSetting('dateRecommendedActionCache', dateRecommendedActionCache)
    }
    return {goodAction, badAction}
  }

  const recommended = useMemo(() => getRecommendedAction(props.date), [props.date])

  return (
    <div className="recommended-action mt-2">
      { recommended.goodAction && <div className="flex justify-between mt-2">
        <div className="p-1">宜</div>
        <div className="good p-1">
          {
            typeof recommended.goodAction == "object" ? (
              <a href={recommended.goodAction.url} target="_blank" style={recommended.goodAction.style}>{recommended.goodAction.title}</a>
            ) : recommended.goodAction
          }
        </div>
      </div>}
      { recommended.badAction && <div className="flex justify-between mt-2">
        <div className="p-1">不宜</div>
        <div className="bad p-1">
          {
            typeof recommended.badAction == "object" ? (
              <a href={recommended.badAction.url} target="_blank" style={recommended.badAction.style}>{recommended.badAction.title}</a>
            ) : recommended.badAction
          }
        </div>
      </div>}
    </div>
  )
};

export default RecommendedAction;