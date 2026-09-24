
import React, { useState, useEffect } from 'react';
import { Switch, Toaster, ToasterPosition } from '@hackplan/uui';
import emitter from '../../lib/EventEmitter';
import { saveSetting } from '../../lib/utils';

const AppToaster = Toaster.create({
  maxToasts: 3,
  position: ToasterPosition.TopRight,
})

const SettingToggle = (props) => {
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    chrome.storage.sync.get([props.storeKey], function(result) {
      if (result && result[props.storeKey]) {
        setChecked(result[props.storeKey]);
      }
    });
  }, []);


  const setSetting = (value) => {
    chrome.storage.sync.set({[props.storeKey]: value}, function() {
      AppToaster.show({
        timeout: 1000,
        message: `${props.title}设置已保存`,
      })
      emitter.emit('settingUpdate', props.storeKey);
    });
    chrome.runtime.sendMessage({action: "settingUpdate"}, function(response) {
      console.log(response);
    });
    saveSetting(props.storeKey, value)
    setChecked(value)
    if (props.onChange) props.onChange({[props.storeKey]: value})
  }

  return (
    <div className={props.className}>
      <Switch value={checked} onChange={setSetting} />
    </div>
  );
};

export default SettingToggle;