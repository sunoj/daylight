import { getLunarDate, getWeekNumber, makeLocalDateKey, parseLocalDateKey } from "@daylight/core-calendar";
import type { DateMark, LocalDateKey, UserSettings } from "@daylight/domain";
import { getMoonCardData, getSolarTermCardData, moonDiscSvg } from "./detail-cards";
import type { SolarTermCardData } from "./detail-cards";
import { canSaveQuickDiary } from "./quick-diary";
import { quickDiaryPlaceholder } from "./quick-diary-placeholder";
import { renderDiaryTimeline } from "./diary-timeline";
import { getLanguage, t } from "./locale";
import { detailCopy } from "./popup-copy";
import type { DetailState } from "./detail-model";
import type { DetailHandlers } from "./page-handlers";
import { solarTermIconSvg } from "./solar-term-icons";

export function renderDetail(state: DetailState, handlers: DetailHandlers): HTMLElement {
  const detail = el("section", "detail", "");
  detail.replaceChildren(
    renderDetailHead(state),
    ...renderHolidaySection(state),
    ...renderCalendarCards(state.selectedDate, state.settings.showLunarDate),
    renderMarkSection(state, handlers),
    renderDiarySection(state, handlers),
  );
  return detail;
}

function renderDetailHead(state: DetailState): HTMLElement {
  const parts = parseLocalDateKey(state.selectedDate);
  const title = el("span", "detail-date", formatMonthDay(parts.month, parts.day));
  const weekday = el("span", "detail-weekday", formatWeekday(state.selectedDate));
  const titleRow = el("div", "detail-title-row", "");
  titleRow.replaceChildren(title, weekday, ...todayPill(state.selectedDate));

  const head = el("div", "detail-head", "");
  head.replaceChildren(titleRow, el("div", "detail-sub", getLunarWeekLabel(state.selectedDate, state.settings.calendarType, state.settings.showLunarDate)));
  return head;
}

function renderCalendarCards(date: LocalDateKey, showLunarDate: boolean): readonly HTMLElement[] {
  const cards: HTMLElement[] = [];
  const term = getSolarTermCardData(date);
  if (showLunarDate && term) cards.push(renderSolarTermCard(term));
  cards.push(renderMoonCard(date));
  return cards;
}

function renderSolarTermCard(term: SolarTermCardData): HTMLElement {
  const icon = el("div", "detail-card-icon solar-term-icon", "");
  // The icon module keys on the Chinese name (小暑), not the SolarTermName enum
  // (minor-heat) — passing the enum returned an empty glyph.
  icon.innerHTML = solarTermIconSvg(term.label, 48, "large");
  return detailInfoCard(icon, t(term.label), term.subtitle);
}

function renderMoonCard(date: LocalDateKey): HTMLElement {
  const moon = getMoonCardData(date);
  const disc = el("div", "detail-card-icon moon-disc", "");
  disc.innerHTML = moonDiscSvg(moon.illumination, moon.limb, 40);
  return detailInfoCard(disc, moon.phaseLabel, moon.info);
}

function detailInfoCard(icon: HTMLElement, title: string, subtitle: string): HTMLElement {
  const text = el("div", "detail-card-text", "");
  text.replaceChildren(el("div", "detail-card-title", title), el("div", "detail-card-sub", subtitle));
  const card = el("section", "detail-info-card", "");
  card.replaceChildren(icon, text);
  return card;
}

function renderHolidaySection(state: DetailState): readonly HTMLElement[] {
  if (state.selectedHolidayEntries.length === 0) return [];
  const chips = el("div", "holiday-detail-list", "");
  chips.replaceChildren(...state.selectedHolidayEntries.map(renderHolidayChip));
  const section = el("section", "detail-section holiday-detail-section", "");
  section.replaceChildren(sectionHeader(t("节假日"), String(state.selectedHolidayEntries.length)), chips);
  return [section];
}

function renderHolidayChip(entry: DetailState["selectedHolidayEntries"][number]): HTMLElement {
  const chip = el("div", "holiday-detail-chip", "");
  const dot = el("span", entry.colorId ? `holiday-detail-dot holiday-${entry.colorId}` : "holiday-detail-dot", "");
  const name = el("span", "holiday-detail-name", holidayName(entry.day));
  const source = el("span", "holiday-detail-source", ` · ${holidayDetail(entry)}`);
  chip.replaceChildren(dot, name, source);
  return chip;
}

function holidayName(day: DetailState["selectedHolidayEntries"][number]["day"]): string {
  const name = day.name?.trim() ?? "";
  return name ? t(name) : holidayTypeName(day.type);
}

function holidayDetail(entry: DetailState["selectedHolidayEntries"][number]): string {
  const source = t(entry.sourceName);
  return entry.day.type === "holiday" ? source : `${source} · ${holidayTypeName(entry.day.type)}`;
}

function holidayTypeName(type: string): string {
  if (type === "workday") return t("调休上班");
  if (type === "observance") return t("纪念日");
  return t("节假日");
}

function renderMarkSection(state: DetailState, handlers: DetailHandlers): HTMLElement {
  const markType = select("mark-type", markTypeOptions());
  const markInput = input("mark-content", "");
  const save = button(detailCopy.saveMark, () => handlers.onSaveMark(markType.value as DateMark["type"], markInput.value), "detail-save");
  const addChip = el("div", "mark-chip add", "");
  addChip.title = detailCopy.add;
  addChip.replaceChildren(el("span", "add-icon", "+"), markType, markInput);

  const chips = el("div", "mark-chips", "");
  chips.replaceChildren(...renderMarkChips(state.selectedMarks, handlers), addChip, save);
  const section = el("section", "detail-section", "");
  section.replaceChildren(sectionHeader(detailCopy.marks, detailCopy.marksCount(state.selectedMarks.length)), chips);
  return section;
}

function renderMarkChips(marks: readonly DateMark[], handlers: DetailHandlers): readonly HTMLElement[] {
  if (marks.length === 0) return [el("span", "empty-chip", detailCopy.noMarks)];
  return marks.map((mark) => {
    const chip = button("", () => handlers.onDeleteMark(mark), "mark-chip");
    chip.title = mark.content;
    chip.replaceChildren(el("span", "mark-dot full", ""), el("span", "mark-content", mark.content), el("span", "mark-badge", detailCopy.markTypes[mark.type]));
    return chip;
  });
}

function renderDiarySection(state: DetailState, handlers: DetailHandlers): HTMLElement {
  const timeline = renderDiaryTimeline(state.diaryThoughts, {
    onDeleteThought: handlers.onDeleteDiaryThought,
    onToggleThought: handlers.onToggleDiaryThought,
  });
  const field = input("diary-input", "");
  field.placeholder = quickDiaryPlaceholder(state.selectedDate, makeTodayKey());
  const save = button(t("保存"), () => {
    if (canSaveQuickDiary(field.value)) handlers.onSaveDiary(field.value);
  }, "detail-save");
  save.disabled = true;
  field.addEventListener("input", () => {
    save.disabled = !canSaveQuickDiary(field.value);
  });
  field.addEventListener("keydown", (event) => {
    if (event.key === "Enter" && canSaveQuickDiary(field.value)) handlers.onSaveDiary(field.value);
  });

  const inputRow = el("div", "diary-input-row", "");
  inputRow.replaceChildren(field, save);
  const card = el("div", "diary-card", "");
  if (timeline) {
    card.append(timeline);
    card.append(el("div", "diary-divider", ""));
  }
  card.append(inputRow);
  const section = el("section", "detail-section diary-section", "");
  section.replaceChildren(sectionHeader(detailCopy.diary, String(state.diaryThoughts.length)), card);
  return section;
}

function sectionHeader(label: string, count: string): HTMLElement {
  const header = el("div", "detail-section-head", "");
  header.replaceChildren(el("span", "", label), el("span", "", count));
  return header;
}

function todayPill(date: LocalDateKey): readonly HTMLElement[] {
  return date === makeTodayKey() ? [el("span", "today-pill", detailCopy.today)] : [];
}

function getLunarWeekLabel(date: LocalDateKey, calendarType: UserSettings["calendarType"], showLunarDate: boolean): string {
  const weekLabel = detailCopy.weekLabel(getWeekNumber(date, calendarType));
  if (!showLunarDate) return weekLabel;
  const lunar = getLunarDate(date);
  const lunarLabel = lunar.ok
    ? t(`${lunar.value.yearName}年 ${lunar.value.monthName}月${lunar.value.dayName}`)
    : "";
  return `${lunarLabel} · ${weekLabel}`;
}

function markTypeOptions(): readonly (readonly [string, string])[] {
  return [
    ["oneTime", detailCopy.markTypes.oneTime],
    ["yearly", detailCopy.markTypes.yearly],
    ["monthly", detailCopy.markTypes.monthly],
  ];
}

function formatMonthDay(month: number, day: number): string {
  if (getLanguage() === "zh" || getLanguage() === "zh-Hant") return `${month}月${day}日`;
  return t("公历月日格式")
    .replace("{month}", getMonthShortName(month))
    .replace("{day}", String(day));
}

function getMonthShortName(month: number): string {
  const names = ["公历一月", "公历二月", "公历三月", "公历四月", "公历五月", "公历六月", "公历七月", "公历八月", "公历九月", "公历十月", "公历十一月", "公历十二月"];
  return t(names[month - 1] ?? "公历一月");
}

function formatWeekday(date: LocalDateKey): string {
  return t(["周日", "周一", "周二", "周三", "周四", "周五", "周六"][new Date(`${date}T00:00:00Z`).getUTCDay()] ?? "周日");
}


function makeTodayKey(): LocalDateKey {
  const now = new Date();
  return makeLocalDateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
}

function button(label: string, onClick: () => void, className = ""): HTMLButtonElement {
  const item = document.createElement("button");
  item.className = className;
  item.textContent = label;
  item.addEventListener("click", onClick);
  return item;
}

function input(name: string, value: string): HTMLInputElement {
  const item = document.createElement("input");
  item.name = name;
  item.value = value;
  return item;
}

function textarea(name: string, value: string): HTMLTextAreaElement {
  const item = document.createElement("textarea");
  item.name = name;
  item.rows = 3;
  item.value = value;
  return item;
}

function select(name: string, options: readonly (readonly [string, string])[]): HTMLSelectElement {
  const item = document.createElement("select");
  item.name = name;
  item.replaceChildren(...options.map(([value, label]) => {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = label;
    return option;
  }));
  return item;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
