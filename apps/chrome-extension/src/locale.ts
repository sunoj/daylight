/**
 * Lightweight localization keyed by the Chinese source string.
 * Exports: Language, t, setLanguage, getLanguage, languageFromLocale, resolveBrowserLanguage, formatCalendarYear, monthShort
 * Deps: domain settings language type, Chrome i18n API
 */

import type { Language } from "@daylight/domain";
import { toTraditional } from "./traditional-chinese";

export type { Language };

let activeLanguage: Language = "zh";

export function setLanguage(language: Language): void {
  activeLanguage = language;
}

export function getLanguage(): Language {
  return activeLanguage;
}

export function t(zh: string): string {
  if (activeLanguage === "zh") return zh;
  if (activeLanguage === "zh-Hant") return toTraditional(zh);
  return table[zh]?.[activeLanguage] || zh;
}

/** Short weekday for the calendar grid header (0 = Sunday). */
export function weekdayShort(index: number): string {
  const names: Record<Language, readonly string[]> = {
    zh: ["日", "一", "二", "三", "四", "五", "六"],
    "zh-Hant": ["日", "一", "二", "三", "四", "五", "六"],
    en: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    th: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"],
  };
  return names[activeLanguage][((index % 7) + 7) % 7] ?? "";
}

/**
 * Calendar-era display year: Thai shows the Buddhist Era (CE + 543), matching
 * the macOS client's Loc.displayYear. Display-only — navigation and grouping
 * stay Gregorian.
 */
export function formatCalendarYear(year: number): string {
  return String(activeLanguage === "th" ? year + 543 : year);
}

/** Short month name for period grids and diary placeholders (1 = January). */
export function monthShort(month: number): string {
  const names: Record<Language, readonly string[]> = {
    zh: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    "zh-Hant": ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    en: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    th: ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."],
  };
  return names[activeLanguage][Math.max(0, Math.min(month - 1, 11))] ?? "";
}

/** Full month name (1 = January), for the calendar header. */
export function monthLong(month: number): string {
  const names: Record<Language, readonly string[]> = {
    zh: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    "zh-Hant": ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    en: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
    th: ["มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"],
  };
  return names[activeLanguage][Math.max(0, Math.min(month - 1, 11))] ?? "";
}

/** Calendar header title, e.g. 2026年8月 / August 2026 / สิงหาคม 2569. */
export function monthTitle(year: number, month: number): string {
  const label = formatCalendarYear(year);
  return activeLanguage === "zh" || activeLanguage === "zh-Hant" ? `${label}年${month}月` : `${monthLong(month)} ${label}`;
}

export function languageFromLocale(locale: string | undefined): Language {
  const normalized = locale?.toLowerCase().replace(/_/g, "-") ?? "";
  const code = normalized.split("-")[0];
  if (code === "zh") {
    return ["hant", "tw", "hk", "mo"].some((part) => normalized.split("-").includes(part)) ? "zh-Hant" : "zh";
  }
  if (code === "th") return "th";
  return "en";
}

export function resolveBrowserLanguage(): Language {
  return languageFromLocale(getChromeUiLanguage() ?? getNavigatorLanguage());
}

function getChromeUiLanguage(): string | undefined {
  return typeof chrome === "undefined" ? undefined : chrome.i18n?.getUILanguage();
}

function getNavigatorLanguage(): string | undefined {
  return typeof navigator === "undefined" ? undefined : navigator.language;
}

const table: Readonly<Record<string, Partial<Record<Exclude<Language, "zh">, string>>>> = {
  "今天": { en: "Today", th: "วันนี้" },
  "刚刚": { en: "just now", th: "เมื่อสักครู่" },
  "删除": { en: "Delete", th: "ลบ" },
  "确认删除": { en: "Confirm deletion", th: "ยืนยันการลบ" },
  "已保存": { en: "Saved", th: "บันทึกแล้ว" },
  "设置": { en: "Settings", th: "การตั้งค่า" },
  "显示": { en: "Display", th: "การแสดงผล" },
  "日历": { en: "Calendar", th: "ปฏิทิน" },
  "工具栏": { en: "Toolbar", th: "แถบเครื่องมือ" },
  "数据与同步": { en: "Data & sync", th: "ข้อมูลและซิงค์" },
  "来源": { en: "Sources", th: "แหล่งที่มา" },
  "订阅链接": { en: "Subscription URL", th: "ลิงก์สมัคร" },
  "自动更新": { en: "Auto update", th: "อัปเดตอัตโนมัติ" },
  "每周": { en: "Weekly", th: "รายสัปดาห์" },
  "显示农历": { en: "Lunar date", th: "ปฏิทินจันทรคติ" },
  "显示周数": { en: "Week numbers", th: "เลขสัปดาห์" },
  "日历类型": { en: "Calendar type", th: "ประเภทปฏิทิน" },
  "图标样式": { en: "Icon mode", th: "รูปแบบไอคอน" },
  "语言": { en: "Language", th: "ภาษา" },
  "国际标准": { en: "ISO 8601", th: "ISO 8601" },
  "美式": { en: "US", th: "สหรัฐฯ" },
  "阿拉伯": { en: "Arabic", th: "อาหรับ" },
  "希伯来": { en: "Hebrew", th: "ฮีบรู" },
  "日期方块": { en: "Date badge", th: "ป้ายวันที่" },
  "表情符号": { en: "Emoji", th: "อีโมจิ" },
  "月相图标": { en: "Moon icon", th: "ไอคอนจันทร์" },
  "订阅法定节假日": { en: "Subscribe holidays", th: "สมัครวันหยุด" },
  "选择多个来源，自动标注放假与调休": { en: "Pick sources to mark holidays automatically", th: "เลือกหลายแหล่งเพื่อทำเครื่องหมายวันหยุดอัตโนมัติ" },
  "订阅节假日": { en: "Holidays", th: "วันหยุด" },
  "未订阅": { en: "Not subscribed", th: "ยังไม่สมัคร" },
  "已订阅": { en: "Subscribed", th: "สมัครแล้ว" },
  "正在同步…": { en: "Syncing...", th: "กำลังซิงค์..." },
  "同步失败": { en: "Sync failed", th: "ซิงค์ไม่สำเร็จ" },
  "未授予订阅权限": { en: "Subscription permission denied", th: "ไม่ได้อนุญาตสิทธิ์สมัคร" },
  "订阅并标注": { en: "Subscribe & mark", th: "สมัครและทำเครื่องหมาย" },
  "中国大陆": { en: "Mainland China", th: "จีนแผ่นดินใหญ่" },
  "中国香港特别行政区": { en: "Hong Kong SAR, China", th: "ฮ่องกง เขตบริหารพิเศษจีน" },
  "中国台湾": { en: "Taiwan, China", th: "ไต้หวัน จีน" },
  "泰国": { en: "Thailand", th: "ประเทศไทย" },
  "自定义 iCal 链接": { en: "Custom iCal URL", th: "ลิงก์ iCal กำหนดเอง" },
  "国务院办公厅 · 官方公告": { en: "State Council · official notices", th: "สภาแห่งรัฐ · ประกาศทางการ" },
  "GovHK 官方日历": { en: "GovHK official calendar", th: "ปฏิทินทางการ GovHK" },
  "行政院人事行政总处": { en: "DGPA Executive Yuan", th: "DGPA Executive Yuan" },
  "officeholidays.com": { en: "officeholidays.com", th: "officeholidays.com" },
  "粘贴任意 .ics 订阅地址": { en: "Paste any .ics URL", th: "วางลิงก์ .ics ใดก็ได้" },
  "名称": { en: "Name", th: "ชื่อ" },
  "留空则自动读取": { en: "Blank imports from feed", th: "เว้นว่างเพื่ออ่านจากฟีด" },
  "{count} 天 / 年": { en: "{count} days / year", th: "{count} วัน / ปี" },
  "{count} 天": { en: "{count} days", th: "{count} วัน" },
  "铁锈": { en: "Rust", th: "สนิม" },
  "石蓝": { en: "Stone", th: "น้ำเงินหิน" },
  "橄榄": { en: "Olive", th: "โอลีฟ" },
  "琥珀": { en: "Amber", th: "อำพัน" },
  "绿": { en: "Green", th: "เขียว" },
  "节假日": { en: "Holidays", th: "วันหยุด" },
  "调休上班": { en: "Adjusted workday", th: "วันทำงานชดเชย" },
  "纪念日": { en: "Observance", th: "วันสำคัญ" },
  "同步": { en: "Sync", th: "ซิงค์" },
  "上一月": { en: "Previous month", th: "เดือนก่อน" },
  "下一月": { en: "Next month", th: "เดือนถัดไป" },
  "下一天": { en: "Next day", th: "วันถัดไป" },
  "标记": { en: "Marks", th: "เครื่องหมาย" },
  "日记": { en: "Diary", th: "ไดอารี่" },
  "二十四节气": { en: "24 solar terms", th: "24 ฤดูกาลย่อย" },
  "{percent}% 照亮": { en: "{percent}% illuminated", th: "สว่าง {percent}%" },
  "新月": { en: "New moon", th: "จันทร์ดับ" },
  "娥眉月": { en: "Waxing crescent", th: "ข้างขึ้นเสี้ยว" },
  "上弦月": { en: "First quarter", th: "จันทร์ครึ่งดวงข้างขึ้น" },
  "盈凸月": { en: "Waxing gibbous", th: "ข้างขึ้นเกือบเต็มดวง" },
  "满月": { en: "Full moon", th: "จันทร์เต็มดวง" },
  "亏凸月": { en: "Waning gibbous", th: "ข้างแรมเกือบเต็มดวง" },
  "下弦月": { en: "Last quarter", th: "จันทร์ครึ่งดวงข้างแรม" },
  "残月": { en: "Waning crescent", th: "ข้างแรมเสี้ยว" },
  "添加": { en: "Add", th: "เพิ่ม" },
  "无标记": { en: "No marks", th: "ไม่มีเครื่องหมาย" },
  "保存标记": { en: "Save mark", th: "บันทึกเครื่องหมาย" },
  "保存日记": { en: "Save diary", th: "บันทึกไดอารี่" },
  "保存": { en: "Save", th: "บันทึก" },
  "记一笔今天…": { en: "Note today…", th: "บันทึกวันนี้…" },
  "月龄": { en: "age", th: "อายุ" },
  "{percent}% 照亮 · 月龄 {age}d": { en: "{percent}% illuminated · age {age}d", th: "สว่าง {percent}% · อายุ {age} วัน" },
  "单次": { en: "once", th: "ครั้งเดียว" },
  "每年": { en: "yearly", th: "รายปี" },
  "每月": { en: "monthly", th: "รายเดือน" },
  "周日": { en: "Sun", th: "อา." },
  "周一": { en: "Mon", th: "จ." },
  "周二": { en: "Tue", th: "อ." },
  "周三": { en: "Wed", th: "พ." },
  "周四": { en: "Thu", th: "พฤ." },
  "周五": { en: "Fri", th: "ศ." },
  "周六": { en: "Sat", th: "ส." },
  "第 {week} 周": { en: "Week {week}", th: "สัปดาห์ที่ {week}" },
  "公历月日格式": { en: "{month} {day}", th: "{day} {month}" },
  "公历一月": { en: "Jan", th: "ม.ค." },
  "公历二月": { en: "Feb", th: "ก.พ." },
  "公历三月": { en: "Mar", th: "มี.ค." },
  "公历四月": { en: "Apr", th: "เม.ย." },
  "公历五月": { en: "May", th: "พ.ค." },
  "公历六月": { en: "Jun", th: "มิ.ย." },
  "公历七月": { en: "Jul", th: "ก.ค." },
  "公历八月": { en: "Aug", th: "ส.ค." },
  "公历九月": { en: "Sep", th: "ก.ย." },
  "公历十月": { en: "Oct", th: "ต.ค." },
  "公历十一月": { en: "Nov", th: "พ.ย." },
  "公历十二月": { en: "Dec", th: "ธ.ค." },
  "上一天": { en: "Previous day", th: "วันก่อนหน้า" },
  "上个月": { en: "Previous month", th: "เดือนก่อนหน้า" },
  "下个月": { en: "Next month", th: "เดือนถัดไป" },
  "日期详情": { en: "Day detail", th: "รายละเอียดวัน" },
  "打开日期详情": { en: "Open date detail", th: "เปิดรายละเอียดวัน" },
  "回到当前月份": { en: "Back to current month", th: "กลับไปเดือนปัจจุบัน" },
  "进入设置页面": { en: "Open settings", th: "เปิดการตั้งค่า" },
  "返回": { en: "Back", th: "กลับ" },
  "返回上一屏": { en: "Go back", th: "กลับหน้าก่อนหน้า" },
  "显示快捷键提示": { en: "Shortcut help", th: "ความช่วยเหลือแป้นพิมพ์ลัด" },
  "关于昼间": { en: "About Daylight", th: "เกี่ยวกับ Daylight" },
  "概览": { en: "Overview", th: "ภาพรวม" },
  "常见问题": { en: "FAQ", th: "คำถามที่พบบ่อย" },
  "最近更新": { en: "Recent updates", th: "อัปเดตล่าสุด" },
  "查询农历、二十四节气、公共假日与月相的日历扩展。": { en: "A calendar extension for lunar dates, 24 solar terms, public holidays, and moon phases.", th: "ส่วนขยายปฏิทินสำหรับปฏิทินจันทรคติ 24 ฤดูกาลย่อย วันหยุดราชการ และดวงจันทร์" },
  "版本": { en: "Version", th: "เวอร์ชัน" },
  "许可证": { en: "License", th: "สัญญาอนุญาต" },
  "联系": { en: "Contact", th: "ติดต่อ" },
  "体验版": { en: "Beta", th: "เบต้า" },
  "问：可以改每周从哪天开始吗？": { en: "Q: Can I change when the week starts?", th: "ถาม: เปลี่ยนวันเริ่มสัปดาห์ได้ไหม?" },
  "答：在设置里切换日历类型，即可决定每周的第一天。": { en: "A: Change Calendar type in Settings to control the first day of the week.", th: "ตอบ: เปลี่ยนประเภทปฏิทินในการตั้งค่าเพื่อกำหนดวันเริ่มสัปดาห์" },
  "问：昼间把数据存在哪里？": { en: "Q: How does Daylight store data?", th: "ถาม: Daylight เก็บข้อมูลอย่างไร?" },
  "答：你添加的日期标记和日记只保存在本机。": { en: "A: Date marks and diary entries you create are stored locally only.", th: "ตอบ: เครื่องหมายและไดอารี่ที่คุณสร้างจะเก็บในเครื่องเท่านั้น" },
  "问：日历信息从哪里来？": { en: "Q: Where does calendar information come from?", th: "ถาม: ข้อมูลปฏิทินมาจากไหน?" },
  "答：公共假日来自同步的远程来源；农历、节气与月相都在本地计算。": { en: "A: Public holidays come from synced remote sources; lunar dates, solar terms, and moon phases are computed locally.", th: "ตอบ: วันหยุดราชการมาจากแหล่งซิงค์ระยะไกล ปฏิทินจันทรคติ ฤดูกาลย่อย และดวงจันทร์คำนวณในเครื่อง" },
  "日记支持 [] 待办，删除改为二次确认，输入框按所选日期提示；移除双日历视图。": { en: "Manifest V3 rewrite with the new popup design, holiday subscriptions, and inline date detail.", th: "รีไรต์ Manifest V3 พร้อมดีไซน์ป๊อปอัปใหม่ การสมัครวันหยุด และรายละเอียดวันในหน้าเดียวกัน" },
};
