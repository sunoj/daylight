/**
 * Browser action icon rendering for date, weekday emoji, and moon phase modes.
 * Exports: renderActionIcon, buildActionTitle
 * Deps: core calendar lunar and moon helpers, domain settings types, icon theme and moon helpers
 */

import { getLunarDate, getSolarTermLabelZh, makeLocalDateKey } from "@daylight/core-calendar";
import type { ActionIconMode, LocalDateKey, UserSettings } from "@daylight/domain";
import { drawMoonGlyph } from "./icon-moon";
import { resolveIconColors, type ToolbarTheme } from "./icon-theme";
import { t } from "./locale";

const WEEKDAY_LABELS_ZH = ["日", "一", "二", "三", "四", "五", "六"] as const;
const WEEKDAY_EMOJI = ["✊", "👍", "✌", "👌", "🖖", "🖐", "🤙"] as const;

export function renderActionIcon(date: Date, settings: UserSettings, theme: ToolbarTheme = "unknown"): ImageData {
  const canvas = new OffscreenCanvas(32, 32);
  const context = canvas.getContext("2d");
  if (!context) throw new Error("Unable to create icon canvas context.");

  const colors = resolveIconColors(theme);
  const dateKey = makeDateKey(date);
  clearCanvas(context);

  const glyph = resolveIconGlyph(settings.actionIconMode);
  if (glyph === "emoji") drawEmojiIcon(context, date);
  else if (glyph === "moon") drawMoonGlyph(context, dateKey, colors.foreground);
  else drawDateIcon(context, date, colors.foreground);
  return context.getImageData(0, 0, 32, 32);
}

export type IconGlyph = "date" | "emoji" | "moon";

/// The glyph is decided by the user's chosen mode alone. The moon used to be
/// gated to 20:00-05:00, carried over from the legacy build where it was an
/// overlay toggle rather than a mode — so picking "Moon icon" during the day
/// silently drew the date icon and the setting looked broken.
export function resolveIconGlyph(mode: ActionIconMode): IconGlyph {
  if (mode === "emoji") return "emoji";
  if (mode === "moonPhase") return "moon";
  return "date";
}

export function buildActionTitle(date: Date): string {
  const dateKey = makeDateKey(date);
  const lunar = getLunarDate(dateKey);
  const weekday = WEEKDAY_LABELS_ZH[date.getDay()];
  const month = date.getMonth() + 1;
  const day = date.getDate();
  if (!lunar.ok) return t(`${month}月${day}日 星期${weekday}`);

  const term = lunar.value.solarTerm ? `(${getSolarTermLabelZh(lunar.value.solarTerm)})` : "";
  return t(`${month}月${day}日 星期${weekday} 农历${lunar.value.monthName}月${lunar.value.dayName}${term}`);
}

function drawDateIcon(context: OffscreenCanvasRenderingContext2D, date: Date, color: string): void {
  context.fillStyle = color;
  context.fillRect(0, 0, 32, 32);
  context.clearRect(2, 8, 28, 22);

  // 18px, judged on a contact sheet at the real 16pt toolbar size rather than
  // enlarged: 13px left the calendar body half empty, 20px pushed the digits
  // into the frame. The original extension used 22px in this same 28x22 body.
  context.font = "bold 18px system-ui, -apple-system, sans-serif";
  context.textAlign = "center";
  context.textBaseline = "middle";
  context.fillStyle = color;
  context.fillText(String(date.getDate()), 16, 20);
}

function drawEmojiIcon(context: OffscreenCanvasRenderingContext2D, date: Date): void {
  context.font = "22px system-ui, -apple-system, sans-serif";
  context.textAlign = "center";
  context.textBaseline = "middle";
  context.fillText(WEEKDAY_EMOJI[date.getDay()] ?? "•", 16, 17);
}

function clearCanvas(context: OffscreenCanvasRenderingContext2D): void {
  context.clearRect(0, 0, 32, 32);
}

function makeDateKey(date: Date): LocalDateKey {
  return makeLocalDateKey(date.getFullYear(), date.getMonth() + 1, date.getDate());
}
