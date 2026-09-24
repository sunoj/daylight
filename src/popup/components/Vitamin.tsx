import React, { useState, useEffect } from 'react';
import { DateTime } from 'luxon';
import { getSetting, saveSetting } from '../../lib/utils';

const loadPromotesFormApi = async () => {
  let response = await fetch("https://vitamin.h5r.cn/api/project/3");
  const data = await response.json();
  if (data && data.allPromotes) {
    saveSetting("vitamin:promotes", data.allPromotes)
    saveSetting("vitamin:lastLoadPromotesAt", DateTime.local().toISO())
  }
}

const markUsed = (key) => {
  const usage = getSetting(key, 0);
  saveSetting(key, usage + 1)
}

const Vitamin = () => {
  const [currentPromote, setCurrentPromote] = useState();
  const [promotes, setPromotes] = useState()

  useEffect(() => {
    if (promotes && promotes.length) setCurrentPromote(promotes[Math.floor(Math.random() * promotes.length)])
  }, [promotes])

  useEffect(() => {
    if (!currentPromote) return
    markUsed(`temporary:vitamin:usage_${DateTime.local().toFormat("o")}_${currentPromote.id}`)
    markUsed(`vitamin:usage_${currentPromote.id}`)
  }, [currentPromote])

  const getPromotes = function () {
    let promotes = getSetting("vitamin:promotes", []);
    let lastLoadPromotesAt = getSetting("vitamin:lastLoadPromotesAt", null)
    if (!lastLoadPromotesAt || DateTime.local().diff(DateTime.fromISO(lastLoadPromotesAt)).as('days') > 1) {
      loadPromotesFormApi()
    }
    promotes = promotes.filter((promote) => {
      const promoteUsedInTotal = getSetting(`vitamin:usage_${promote.id}`, 0)
      const usageToday = getSetting(`temporary:vitamin:usage_${DateTime.local().toFormat("o")}_${promote.id}`, 0);
      const isStarted = promote.startAt ? DateTime.fromJSDate(new Date(promote.startAt)) < DateTime.local() : true
      const isValid = promote.endAt ? DateTime.fromJSDate(new Date(promote.endAt)) > DateTime.local() : true
      const isOverUsedToday = usageToday >= promote.dailyLimit
      const isOverUsedInTotal = promote.totalLimit && promoteUsedInTotal >= promote.totalLimit

      return isValid && isStarted && !isOverUsedToday && !isOverUsedInTotal
    });
    setPromotes(promotes)
    return promotes;
  }

  useEffect(() => {
    getPromotes()
  }, [])


  return (
    <div>
      {currentPromote && <div className="h-full" aria-label={currentPromote.description} data-microtip-position="top" role="tooltip">
        <a className="center-card text-xs flex items-center" href={currentPromote.url} target="_blank">
          { currentPromote.iconSrc && <img className="pr-2" style={{ height: "1em" }} src={currentPromote.iconSrc}></img>}
          { !currentPromote.iconSrc && currentPromote.icon && <img className="pr-2" style={{ height: "1em" }} src={currentPromote.icon.publicUrl}></img>}
          <span>{currentPromote.title}</span>
        </a>
      </div>
      }
    </div>
  );
};

export default Vitamin;