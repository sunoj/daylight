/**
 * Manifest V3 service worker for scheduled sync and action icon refresh.
 * Exports: none, registers Chrome runtime and alarm listeners
 * Deps: Chrome repositories, icon renderer, sync package
 */

import { createChromeRepositories } from "./chrome-repositories";
import { refreshHolidaySubscriptions } from "./holiday-subscriptions";
import { buildActionTitle, renderActionIcon } from "./icon-renderer";
import { setLanguage } from "./locale";
import type { ToolbarTheme } from "./icon-theme";

const ICON_ALARM = "refresh-action-icon";
const HOLIDAY_ALARM = "refresh-holiday-subscriptions";
const repositories = createChromeRepositories();

chrome.runtime.onInstalled.addListener(() => {
  chrome.alarms.create(ICON_ALARM, { delayInMinutes: 0.1, periodInMinutes: 10 });
  void chrome.alarms.clear("sync-public-calendar");
  chrome.alarms.create(HOLIDAY_ALARM, { delayInMinutes: 1, periodInMinutes: 720 });
  void refreshActionIcon();
  void refreshHolidaySubscriptions(repositories, { requestCustomPermissions: false });
});

chrome.runtime.onStartup.addListener(() => {
  chrome.alarms.create(HOLIDAY_ALARM, { delayInMinutes: 1, periodInMinutes: 720 });
  void refreshActionIcon();
});

chrome.runtime.onMessage.addListener((message) => {
  if (isSettingsChangedMessage(message)) void refreshActionIcon();
  if (isToolbarThemeMessage(message)) void updateToolbarTheme(message.theme);
});

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === ICON_ALARM) void refreshActionIcon();
  if (alarm.name === HOLIDAY_ALARM) void refreshHolidaySubscriptions(repositories, { requestCustomPermissions: false });
});

async function refreshActionIcon(): Promise<void> {
  const settings = await repositories.settings.getSettings();
  if (!settings.ok) return;
  const theme = await repositories.toolbarTheme.getTheme();
  const now = new Date();
  setLanguage(settings.value.language);
  chrome.action.setTitle({ title: buildActionTitle(now) });
  chrome.action.setIcon({ imageData: renderActionIcon(now, settings.value, theme) });
}

async function updateToolbarTheme(theme: ToolbarTheme): Promise<void> {
  const current = await repositories.toolbarTheme.getTheme();
  if (current === theme) return;
  await repositories.toolbarTheme.saveTheme(theme);
  await refreshActionIcon();
}

function isSettingsChangedMessage(message: unknown): message is { readonly type: "settings-changed" } {
  return typeof message === "object" && message !== null && "type" in message && message.type === "settings-changed";
}

function isToolbarThemeMessage(message: unknown): message is { readonly type: "toolbar-theme-changed"; readonly theme: ToolbarTheme } {
  return typeof message === "object"
    && message !== null
    && "type" in message
    && message.type === "toolbar-theme-changed"
    && "theme" in message
    && (message.theme === "light" || message.theme === "dark");
}
