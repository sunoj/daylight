/**
 * Calendar month grid rendering for the popup.
 * Exports: renderMonthStack
 * Deps: core-calendar, popup model, text truncation
 */

import {
  buildMonthGrid,
  getDayCellSubtitle,
  getSolarTermLabelZh,
  getWeekNumber,
  getWeekday,
  holidayHitsForDate,
  makeLocalDateKey,
  parseLocalDateKey,
  resolvePublicDay,
} from "@daylight/core-calendar";
import type { DateMark, LocalDateKey, UserSettings } from "@daylight/domain";
import type { PopupState } from "./popup-model";
import { getLanguage, t, weekdayShort } from "./locale";
import { truncateCellSubtitle } from "./text-truncate";
import type { CalendarHandlers } from "./popup-render";

export function renderMonthStack(state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const stack = el("div", "month-stack", "");
  stack.append(renderMonth(state.visibleYear, state.visibleMonth, state, handlers));
  return stack;
}

function renderMonth(year: number, month: number, state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const grid = buildMonthGrid({
    year,
    month,
    today: makeTodayKey(),
    calendarType: state.settings.calendarType,
    showLunarDate: state.settings.showLunarDate,
    publicDays: state.publicDays,
  });
  const section = el("section", "", "");
  const weekdays = el("div", "weekday-wrap", "");
  weekdays.append(renderWeekdays(state.settings.calendarType, state.settings.showWeekNumbers));
  const gridWrap = el("div", "grid-wrap", "");
  const hasSubtitle = grid.days.some((day) => hasDaySubtitle(day, state));
  const gridClasses = `${gridClass("grid", state.settings.showWeekNumbers)}${hasSubtitle ? "" : " compact"}`;
  const days = el("div", gridClasses, "");
  days.replaceChildren(...renderGridCells(grid.days, state, handlers));
  gridWrap.append(days);
  section.replaceChildren(weekdays, gridWrap);
  return section;
}

function hasDaySubtitle(day: ReturnType<typeof buildMonthGrid>["days"][number], state: PopupState): boolean {
  const publicDay = resolvePublicDay(day.date, state.holidayHits, state.publicDays);
  const subtitle = getDayCellSubtitle(
    publicDay,
    day.lunarDate,
    state.settings.showLunarDate,
    getSolarTermLabelZh,
  );
  return !!subtitle?.text;
}

function renderWeekdays(calendarType: UserSettings["calendarType"], showWeekNumbers: boolean): HTMLElement {
  const first = calendarType === "iso8601" ? 1 : calendarType === "arabic" ? 6 : 0;
  const weekdayIndices = Array.from({ length: 7 }, (_, offset) => (first + offset) % 7);
  const row = el("div", gridClass("weekdays", showWeekNumbers), "");
  const weekNumber = showWeekNumbers ? [el("span", "week-no", "#")] : [];
  row.replaceChildren(...weekNumber, ...weekdayIndices.map((weekday) => {
    const className = weekday === 0 || weekday === 6 ? "weekday weekend" : "weekday";
    return el("span", className, weekdayShort(weekday).toUpperCase());
  }));
  return row;
}

function renderGridCells(
  days: ReturnType<typeof buildMonthGrid>["days"],
  state: PopupState,
  handlers: CalendarHandlers,
): readonly HTMLElement[] {
  const cells: HTMLElement[] = [];
  for (let index = 0; index < days.length; index += 7) {
    if (state.settings.showWeekNumbers) {
      cells.push(renderWeekNumber(days[index]?.date ?? state.selectedDate, state.settings.calendarType));
    }
    cells.push(...days.slice(index, index + 7).map((day) => renderDayCell(day, state, handlers)));
  }
  return cells;
}

function renderDayCell(
  day: ReturnType<typeof buildMonthGrid>["days"][number],
  state: PopupState,
  handlers: CalendarHandlers,
): HTMLButtonElement {
  const marks = state.marks.filter((mark) => doesMarkMatch(mark, day.date));
  const parts = parseLocalDateKey(day.date);
  const isWeekend = getWeekday(day.date) === 0 || getWeekday(day.date) === 6;
  const classes = [
    "day",
    day.isOutsideMonth ? "outside" : "",
    day.isToday ? "today" : "",
    day.date === state.selectedDate ? "selected" : "",
    isWeekend ? "weekend" : "",
  ].join(" ");
  const cell = button("", () => handlers.onSelectDate(day.date), classes);
  const publicDay = resolvePublicDay(day.date, state.holidayHits, state.publicDays);
  const isWorkday = holidayHitsForDate(day.date, state.holidayHits).some((hit) => hit.day.type === "workday")
    || publicDay?.type === "workday";
  const subtitle = getDayCellSubtitle(
    publicDay,
    day.lunarDate,
    state.settings.showLunarDate,
    getSolarTermLabelZh,
  );
  const dots = holidayHitsForDate(day.date, state.holidayHits).map((hit) => hit.subscription.colorId);
  const subtitleEl = el("span", subtitleClass(subtitle), subtitle ? truncateCellSubtitle(t(subtitle.text)) : "");
  cell.replaceChildren(
    el("span", "num", String(parts.day)),
    subtitleEl,
    renderMarks(marks),
    renderHolidayDots(dots),
  );
  if (isWorkday) {
    cell.classList.add("workday");
    const badge = el("span", "workday-badge", getLanguage() === "zh" || getLanguage() === "zh-Hant" ? "班" : "W");
    badge.title = t("调休上班");
    badge.setAttribute("aria-label", t("调休上班"));
    cell.append(badge);
  }
  return cell;
}

function subtitleClass(subtitle: ReturnType<typeof getDayCellSubtitle>): string {
  if (!subtitle) return "lunar";
  return subtitle.isSolarTerm ? "lunar solar-term" : "lunar";
}

function renderWeekNumber(date: LocalDateKey, calendarType: UserSettings["calendarType"]): HTMLElement {
  return el("div", "week-no", String(getWeekNumber(date, calendarType)));
}

function renderMarks(marks: readonly DateMark[]): HTMLElement {
  const wrapper = el("span", "marks", "");
  wrapper.replaceChildren(...marks.slice(0, 3).map(() => el("span", "mark-dot", "")));
  return wrapper;
}

function renderHolidayDots(colorIds: readonly string[]): HTMLElement {
  const wrapper = el("span", "holiday-dots", "");
  wrapper.replaceChildren(...colorIds.slice(0, 3).map((id) => el("span", `holiday-dot holiday-${id}`, "")));
  return wrapper;
}

function gridClass(base: string, showWeekNumbers: boolean): string {
  return showWeekNumbers ? `${base} with-week-numbers` : base;
}


function makeTodayKey(): LocalDateKey {
  const now = new Date();
  return makeLocalDateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
}

function doesMarkMatch(mark: DateMark, date: LocalDateKey): boolean {
  const parts = parseLocalDateKey(date);
  if (mark.type === "yearly") return mark.month === parts.month && mark.day === parts.day;
  if (mark.type === "monthly") return mark.day === parts.day;
  return mark.date === date;
}

function button(label: string, onClick: () => void, className = ""): HTMLButtonElement {
  const item = document.createElement("button");
  item.className = className;
  item.textContent = label;
  item.addEventListener("click", onClick);
  return item;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
