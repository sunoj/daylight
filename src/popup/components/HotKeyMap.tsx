import React from 'react';
import { Dialog, Tag } from '@hackplan/uui';

const HotKeyMap = (props) => {
  return (
    <Dialog className="w-32" open={props.open} focusTrap={true} customize={
      {
        Container: { extendClassName: 'relative' }
      }
    }>
      <h3 className="text-lg">快捷键</h3>
      <button className="float-right cursor-pointer leading-4 p-4 absolute top-0 right-0" onClick={props.onClose}>྾</button>
      <div className="flex flex-col justify-around w-64 min-h-48 max-h-64 overflow-auto">
        { props.keyMap && Object.keys(props.keyMap).length > 0 && Object.keys(props.keyMap).map((actionName) => {
            const { sequences, name } = props.keyMap[actionName];
            return (
              <div className="flex justify-between" key={actionName}>
                <div className="px-2 self-center m-1">
                  { name || actionName }
                </div>
                <div>
                  { sequences.map(({sequence}) => <Tag className="transform scale-75" key={sequence as string}>{sequence}</Tag>) }
                </div>
              </div>
            );
          })
        }
      </div>
    </Dialog>
  );
};

export default HotKeyMap;