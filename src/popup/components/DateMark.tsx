import React, { useState, useMemo, useEffect } from 'react';
import { DateTime } from 'luxon';
import PouchDB from 'pouchdb';
import { Toaster, ToasterPosition } from '@hackplan/uui';

const localDB_mark = new PouchDB('mark')

const AppToaster = Toaster.create({
  maxToasts: 3,
  position: ToasterPosition.TopRight,
})

const DateMarkItem = (props) => {
  const [type, setType] = useState(props.item.type);
  const [content, setContent] = useState(props.item.content);
  const [editMark, setEditMark] = useState(props.item.draft || false);

  const tips = useMemo(() => {
    let dateText = ""
    switch (type) {
      case "yearly":
        dateText = DateTime.fromJSDate(props.date).toFormat("L月d日")
        break;
      case "monthly":
        dateText = DateTime.fromJSDate(props.date).toFormat("d日")
        break;
      case "onetime":
        dateText = DateTime.fromJSDate(props.date).toFormat("y年L月d日")
        break;
      default:
        break;
    }
    return `输入${dateText}的标记`
  }, [type, props.date])

  const onChange = () => {
    if (props.onChange) props.onChange({ type: type, content: content });
    setEditMark(false)
  }

  return <div className={`mark-item w-5/6 ${props.className ? props.className : ''}`} >
    {
      editMark ? <div className="mt-1 w-full relative rounded-md shadow-sm">
        <input type="text" className="form-input block p-0 text-sm leading-5" style={{paddingLeft: "3.5rem"}} placeholder={tips} value={content} onChange={(e) => setContent(e.target.value)} onKeyPress={(e) => {
          if (e.nativeEvent.keyCode === 13) {
            onChange()
          }
        }} />
        <div className="absolute inset-y-0 left-0 flex items-center">
          <select value={type} onChange={(e) => { setType(e.target.value) }} className="form-select h-full py-0 pl-2 pr-7 border-transparent bg-transparent text-gray-500 text-sm leading-5">
            <option value="yearly">每年</option>
            <option value="monthly">每月</option>
            <option value="onetime">单次</option>
          </select>
        </div>
        <div onClick={onChange} className="absolute inset-y-0 right-0 pl-2 pr-2 cursor-pointer flex items-center ">
          <span className="text-gray-500 text-sm leading-5">✔</span>
        </div>
      </div> : <div className={`text-sm ${type}`} onClick={() => { setEditMark((value => !value)) }}>{content}</div>
    }
  </div>
};


export const getKeyByDateType = (date, type) => {
  let key = ""
  switch (type) {
    case "yearly":
      key = DateTime.fromJSDate(date).toFormat("L-d")
      break;
    case "monthly":
      key = DateTime.fromJSDate(date).toFormat("d")
      break;
    case "onetime":
      key = DateTime.fromJSDate(date).toFormat("y-L-d")
      break;
    default:
      break;
  }
  return `${type}:${key}`
}

const DateMark = (props) => {
  const [currentMark, setCurrentMark] = useState<{
    [key: string]: any;
  }>(null);

  useEffect(() => {
    if (!props.mark) return setCurrentMark(null)
    setCurrentMark(props.mark)
  }, [props.mark])

  const updateMark = (item, doc?) => {
    const itemKey = getKeyByDateType(props.date, item.type)
    if (doc.draft && props.mark) {
      doc = props.mark[item.type]
    }
    if (!item.content || item.content.length == 0) {
      delete currentMark[item.type]
      setCurrentMark({
        ...currentMark
      })
      return localDB_mark.remove(doc).then(function () {
        AppToaster.show({
          timeout: 1000,
          message: `标记已删除`,
        })
        if (props.onChange) props.onChange()
      }).catch((err) => {
        console.log(err, item, doc);
      })
    }
    localDB_mark.put({
      _id: itemKey,
      ...(doc ? { _rev: doc._rev } : {}),
      type: item.type,
      content: item.content
    }, {
      force: true
    }).then(function () {
      AppToaster.show({
        timeout: 1000,
        message: `标记已保存`,
      })
      if (props.onChange) props.onChange()
    }).catch((err) => {
      console.log(err, item, doc);
    })
  }

  const leftTypes = useMemo(() => ["yearly", "monthly", "onetime"].filter(function (v) { return !currentMark || Object.keys(currentMark).indexOf(v) == -1 }), [currentMark])

  return (
    <div className="mark">
      <div className="flex flex-col justify-center items-center">
        {
          currentMark && Object.keys(currentMark).map((keyName, i) => {
            return (
              <DateMarkItem key={currentMark[keyName]._id} item={currentMark[keyName]} date={props.date} onChange={(updatedItem) => updateMark(updatedItem, currentMark[keyName])} />
            )
          })
        }
      </div>
      <div className="absolute right-0 bottom-0">
        { leftTypes && leftTypes.length > 0 && <span aria-label="标记日期" data-microtip-position="top-left" role="tooltip">
          <button className="p-2 text-sm action-icon" onClick={() => {
            setCurrentMark({
              ...currentMark, [leftTypes[0]]:
              {
                _id: `new_${leftTypes[0]}`,
                type: leftTypes[0],
                content: '',
                draft: true
              }
            })
          }}>⚑</button>
        </span>}
      </div>
    </div>
  )
}

export default DateMark;