export const getSetting = (settingKey, defaultValue) => {
  let setting = localStorage.getItem(settingKey)
  if (setting) {
    try {
      setting = JSON.parse(setting)
    } catch (error) {
      return setting
    }
  }
  return typeof setting != "undefined" && setting !== null ? setting : defaultValue
}

export const saveSetting = (settingKey, value) => {
  return localStorage.setItem(settingKey, JSON.stringify(value))
}

export const getSettingsWithDefault = (settingsWithDefaultValue: any) => {
  let settings: any = {}
  for (let key in settingsWithDefaultValue) {
    settings[key] = getSetting(key, settingsWithDefaultValue[key])
  }
  return settings
}