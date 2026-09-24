// Lightweight localization keyed by the Chinese source string.
// Exports: AppLanguage, L (global lookup), Loc
// Deps: Foundation

import Foundation

enum AppLanguage: String, CaseIterable {
    case zh
    case zhHant = "zh-Hant"
    case en
    case th

    var displayName: String {
        switch self {
        case .zh: return "简"
        case .zhHant: return "繁"
        case .en: return "EN"
        case .th: return "ไทย"
        }
    }

    static var systemDefault: AppLanguage {
        let preferred = (Locale.preferredLanguages.first ?? "").lowercased().replacingOccurrences(of: "_", with: "-")
        if preferred.hasPrefix("zh-") && (["hant", "tw", "hk", "mo"].contains { preferred.contains($0) }) {
            return .zhHant
        }
        switch Locale.current.language.languageCode?.identifier {
        case "zh": return .zh
        case "th": return .th
        default: return .en
        }
    }
}

/// Shorthand: `L("设置")` returns the string in the active language.
func L(_ zh: String) -> String { Loc.t(zh) }

enum Loc {
    /// Active language — set from settings before each render pass.
    static var language: AppLanguage = .zh

    static func t(_ zh: String) -> String {
        if language == .zh { return zh }
        if language == .zhHant { return TraditionalChinese.convert(zh) }
        return table[zh]?[language] ?? zh
    }

    /// Calendar-era display year: Thai shows the Buddhist Era (CE + 543).
    /// Display-only — navigation and grouping stay Gregorian.
    static func displayYear(_ year: Int) -> Int {
        language == .th ? year + 543 : year
    }

    /// Short weekday for calendar grid headers (0 = Sunday).
    static func weekdayShort(_ index: Int) -> String {
        let names: [AppLanguage: [String]] = [
            .zh: ["日", "一", "二", "三", "四", "五", "六"],
            .zhHant: ["日", "一", "二", "三", "四", "五", "六"],
            .en: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
            .th: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
        ]
        let list = names[language] ?? names[.en]!
        return list[(index % 7 + 7) % 7]
    }

    /// Short month name for period grids and detail titles (1 = January).
    static func monthShort(_ month: Int) -> String {
        let names: [AppLanguage: [String]] = [
            .zh: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
            .zhHant: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
            .en: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
            .th: ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."]
        ]
        let list = names[language] ?? names[.en]!
        return list[max(0, min(month - 1, 11))]
    }

    /// Full month name for the Luna header.
    static func monthLong(_ month: Int) -> String {
        let names: [AppLanguage: [String]] = [
            .zh: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
            .zhHant: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
            .en: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
            .th: ["มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"]
        ]
        let list = names[language] ?? names[.en]!
        return list[max(0, min(month - 1, 11))]
    }

    /// Localized Luna month title with Thai Buddhist-era display years.
    static func monthTitle(year: Int, month: Int, compact: Bool = false) -> String {
        switch language {
        case .zh, .zhHant: return "\(displayYear(year))年\(month)月"
        case .en, .th: return "\(compact ? monthShort(month) : monthLong(month)) \(displayYear(year))"
        }
    }

    /// Quick-diary placeholder. Naming the selected day matters here: the input
    /// writes into whatever date is selected, and a fixed "今天" read as if the
    /// note would land on today.
    static func quickDiaryPlaceholder(for date: LocalDate, today: LocalDate) -> String {
        guard date != today else { return L("记一笔今天…") }
        switch language {
        case .zh, .zhHant: return L("记一笔 \(monthShort(date.month))\(date.day)日…")
        case .en: return "Note \(monthShort(date.month)) \(date.day)…"
        case .th: return "บันทึก \(date.day) \(monthShort(date.month))…"
        }
    }

    /// Weekday full name (0 = Sunday) in the active language.
    static func weekday(_ index: Int) -> String {
        let names: [AppLanguage: [String]] = [
            .zh: ["周日", "周一", "周二", "周三", "周四", "周五", "周六"],
            .zhHant: ["週日", "週一", "週二", "週三", "週四", "週五", "週六"],
            .en: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
            .th: ["อา.", "จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส."]
        ]
        let list = names[language] ?? names[.en]!
        return list[(index % 7 + 7) % 7]
    }

    private static let table: [String: [AppLanguage: String]] = [
        // Main / quick diary
        "记一笔今天…": [.en: "Note today…", .th: "บันทึกวันนี้…"],
        "保存": [.en: "Save", .th: "บันทึก"],
        "已保存": [.en: "Saved", .th: "บันทึกแล้ว"],
        "刚刚": [.en: "just now", .th: "เมื่อสักครู่"],
        "已添加": [.en: "Added", .th: "เพิ่มแล้ว"],
        "已删除": [.en: "Removed", .th: "ลบแล้ว"],
        "删除": [.en: "Delete", .th: "ลบ"],
        "确认删除": [.en: "Confirm deletion", .th: "ยืนยันการลบ"],
        "已导出": [.en: "Exported", .th: "ส่งออกแล้ว"],
        "导出失败": [.en: "Export failed", .th: "ส่งออกไม่สำเร็จ"],
        "已订阅": [.en: "Subscribed", .th: "สมัครแล้ว"],
        "照亮": [.en: "lit", .th: "สว่าง"],
        "月龄": [.en: "age", .th: "อายุ"],
        "查看 3D 月相": [.en: "View 3D moon", .th: "ดูดวงจันทร์ 3D"],
        // Moon phases
        "新月": [.en: "New Moon", .th: "จันทร์ดับ"],
        "娥眉月": [.en: "Waxing Crescent", .th: "จันทร์เสี้ยวข้างขึ้น"],
        "上弦月": [.en: "First Quarter", .th: "จันทร์กึ่งดวงข้างขึ้น"],
        "盈凸月": [.en: "Waxing Gibbous", .th: "จันทร์ค่อนดวงข้างขึ้น"],
        "满月": [.en: "Full Moon", .th: "จันทร์เต็มดวง"],
        "亏凸月": [.en: "Waning Gibbous", .th: "จันทร์ค่อนดวงข้างแรม"],
        "下弦月": [.en: "Last Quarter", .th: "จันทร์กึ่งดวงข้างแรม"],
        "残月": [.en: "Waning Crescent", .th: "จันทร์เสี้ยวข้างแรม"],
        // Settings
        "设置": [.en: "Settings", .th: "การตั้งค่า"],
        "显示": [.en: "Display", .th: "การแสดงผล"],
        "外观": [.en: "Appearance", .th: "ธีม"],
        "语言": [.en: "Language", .th: "ภาษา"],
        "跟随": [.en: "Auto", .th: "อัตโนมัติ"],
        "浅": [.en: "Light", .th: "สว่าง"],
        "深": [.en: "Dark", .th: "มืด"],
        "显示农历": [.en: "Lunar date", .th: "ปฏิทินจันทรคติ"],
        "界面模式": [.en: "Interface mode", .th: "โหมดหน้าจอ"],
        "系统日历": [.en: "System calendar", .th: "ปฏิทินระบบ"],
        "日程": [.en: "Agenda", .th: "กำหนดการ"],
        "显示系统日历": [.en: "Show system calendar", .th: "แสดงปฏิทินระบบ"],
        "选择要显示的日历": [.en: "Choose calendars to show", .th: "เลือกปฏิทินที่จะแสดง"],
        "打开系统设置": [.en: "Open System Settings", .th: "เปิดการตั้งค่าระบบ"],
        "全天": [.en: "All day", .th: "ทั้งวัน"],
        "过往日程": [.en: "Past events", .th: "กิจกรรมที่ผ่านมา"],
        "今天没有日程": [.en: "No events today", .th: "วันนี้ไม่มีกิจกรรม"],
        "没有日程": [.en: "No events", .th: "ไม่มีกิจกรรม"],
        "已连接": [.en: "Connected", .th: "เชื่อมต่อแล้ว"],
        "授权访问日历": [.en: "Authorize calendar access", .th: "อนุญาตปฏิทิน"],
        "在日历中打开": [.en: "Open in Calendar", .th: "เปิดในปฏิทิน"],
        "允许访问系统日历": [.en: "Allow access to your system calendars", .th: "อนุญาตให้เข้าถึงปฏิทินระบบ"],
        "现在": [.en: "Now", .th: "ตอนนี้"],
        "个日历": [.en: "calendars", .th: "ปฏิทิน"],
        // Prefix for the footer countdown in languages that lead with it
        // ("in 38 min."); Chinese trails instead ("38 分钟后") and never uses it.
        "还有": [.en: "in", .th: "ใน"],
        "分钟": [.en: "min.", .th: "นาที"],
        "小时": [.en: "h", .th: "ชม."],
        "每日详情": [.en: "Daily detail", .th: "รายละเอียดรายวัน"],
        "显示周数": [.en: "Week numbers", .th: "เลขสัปดาห์"],
        "日历": [.en: "Calendar", .th: "ปฏิทิน"],
        "每周起始日": [.en: "Week starts", .th: "เริ่มสัปดาห์"],
        "周一": [.en: "Mon", .th: "จันทร์"],
        "周日": [.en: "Sun", .th: "อาทิตย์"],
        "日历类型": [.en: "Calendar type", .th: "ประเภทปฏิทิน"],
        "国际标准": [.en: "ISO 8601", .th: "ISO 8601"],
        "美式": [.en: "US", .th: "สหรัฐฯ"],
        "阿拉伯": [.en: "Arabic", .th: "อาหรับ"],
        "希伯来": [.en: "Hebrew", .th: "ฮีบรู"],
        "工具栏": [.en: "Menu Bar", .th: "แถบเมนู"],
        "开机启动": [.en: "Launch at login", .th: "เปิดเมื่อเข้าสู่ระบบ"],
        "开机启动设置未生效": [.en: "Launch-at-login setting did not take effect", .th: "การตั้งค่าเปิดเมื่อเข้าสู่ระบบไม่มีผล"],
        "状态栏样式": [.en: "Status bar", .th: "แถบสถานะ"],
        "数据与同步": [.en: "Data & Sync", .th: "ข้อมูลและซิงค์"],
        "订阅节假日": [.en: "Holidays", .th: "วันหยุด"],
        "未订阅": [.en: "Not subscribed", .th: "ยังไม่สมัคร"],
        "导出日记": [.en: "Export diary", .th: "ส่งออกไดอารี่"],
        "检查更新": [.en: "Check for updates", .th: "ตรวจหาการอัปเดต"],
        "此构建不包含自动更新": [.en: "Updates unavailable in this build", .th: "บิลด์นี้ไม่รองรับการอัปเดตอัตโนมัติ"],
        "本地构建未包含自动更新组件。前往下载页面获取最新版本？": [
            .en: "Auto-update isn't available in this local build of Daylight. Open the download page instead?",
            .th: "บิลด์ในเครื่องนี้ไม่มีตัวอัปเดตอัตโนมัติ เปิดหน้าดาวน์โหลดแทนหรือไม่?",
        ],
        "前往下载": [.en: "Download", .th: "ดาวน์โหลด"],
        "取消": [.en: "Cancel", .th: "ยกเลิก"],
        "关于": [.en: "About", .th: "เกี่ยวกับ"],
        "退出 Daylight": [.en: "Quit Daylight", .th: "ออกจาก Daylight"],
        "版本": [.en: "Version", .th: "เวอร์ชัน"],
        "昼间 · 100% 本地计算 · 无网络请求": [.en: "Daylight · 100% on-device · No network", .th: "Daylight · คำนวณในเครื่อง · ไม่ใช้เน็ต"],
        "无": [.en: "None", .th: "ไม่มี"],
        // Status editor
        "状态栏": [.en: "Status Bar", .th: "แถบสถานะ"],
        "已启用 · 上下调整顺序": [.en: "Enabled · reorder ↑↓", .th: "เปิดใช้ · จัดลำดับ ↑↓"],
        "可添加": [.en: "Available", .th: "เพิ่มได้"],
        "格式": [.en: "Format", .th: "รูปแบบ"],
        "24 小时制": [.en: "24-hour", .th: "24 ชั่วโมง"],
        "状态栏为空": [.en: "Status bar is empty", .th: "แถบสถานะว่าง"],
        "月相图标": [.en: "Moon icon", .th: "ไอคอนจันทร์"],
        "日期方块": [.en: "Date badge", .th: "ป้ายวันที่"],
        "公历日": [.en: "Day number", .th: "วันที่"],
        "农历日": [.en: "Lunar day", .th: "วันจันทรคติ"],
        "星期": [.en: "Weekday", .th: "วันในสัปดาห์"],
        "时间": [.en: "Time", .th: "เวลา"],
        // Date detail
        "今天": [.en: "Today", .th: "วันนี้"],
        "节假日": [.en: "Holidays", .th: "วันหยุด"],
        "调休上班": [.en: "Adjusted workday", .th: "วันทำงานชดเชย"],
        "纪念日": [.en: "Observance", .th: "วันสำคัญ"],
        "二十四节气": [.en: "24 solar terms", .th: "24 ฤดูกาลจีน"],
        "同步": [.en: "Sync", .th: "ซิงค์"],
        "日记": [.en: "Diary", .th: "ไดอารี่"],
        "新建日记": [.en: "New diary entry", .th: "สร้างบันทึกใหม่"],
        "保存日记": [.en: "Save diary", .th: "บันทึกไดอารี่"],
        "单次": [.en: "once", .th: "ครั้งเดียว"],
        "每年": [.en: "yearly", .th: "รายปี"],
        "每月": [.en: "monthly", .th: "รายเดือน"],
        // Location prompt
        "允许「昼间」使用你的位置？": [.en: "Let Daylight use your location?", .th: "ให้ Daylight ใช้ตำแหน่งของคุณ?"],
        "3D 月相会根据你的经纬度计算月亮的方位角、高度角与天平动，呈现今夜真实的朝向。位置仅在本地使用，不会上传或分享。": [
            .en: "The 3D moon uses your coordinates to compute the moon's azimuth, altitude and libration for tonight's true orientation. Location stays on-device and is never uploaded or shared.",
            .th: "ดวงจันทร์ 3D ใช้พิกัดของคุณคำนวณมุมและการหันของดวงจันทร์คืนนี้ ตำแหน่งอยู่ในเครื่องเท่านั้น ไม่อัปโหลดหรือแชร์"
        ],
        "仅本地计算": [.en: "On-device only", .th: "ในเครื่องเท่านั้น"],
        "可随时关闭": [.en: "Off anytime", .th: "ปิดได้ทุกเมื่อ"],
        "允许使用定位": [.en: "Allow location", .th: "อนุญาตตำแหน่ง"],
        "暂不开启": [.en: "Not now", .th: "ไม่ใช่ตอนนี้"],
        // 3D moon
        "3D 月相": [.en: "3D Moon", .th: "ดวงจันทร์ 3D"],
        "正在获取位置…": [.en: "Locating…", .th: "กำลังระบุตำแหน่ง…"],
        "使用当前位置": [.en: "Using current location", .th: "ใช้ตำแหน่งปัจจุบัน"],
        "未授权": [.en: "not authorized", .th: "ไม่ได้รับอนุญาต"],
        // Holidays
        "订阅法定节假日": [.en: "Subscribe holidays", .th: "สมัครวันหยุด"],
        "选择一个来源，自动标注放假与调休": [.en: "Pick a source to mark holidays automatically", .th: "เลือกแหล่งเพื่อทำเครื่องหมายวันหยุดอัตโนมัติ"],
        "选择多个来源，自动标注放假与调休": [.en: "Pick sources to mark holidays automatically", .th: "เลือกหลายแหล่งเพื่อทำเครื่องหมายวันหยุดอัตโนมัติ"],
        "来源": [.en: "Source", .th: "แหล่ง"],
        "订阅链接": [.en: "Subscription URL", .th: "ลิงก์สมัคร"],
        "名称": [.en: "Name", .th: "ชื่อ"],
        "留空则自动读取": [.en: "Leave blank to import", .th: "เว้นว่างเพื่ออ่านอัตโนมัติ"],
        "粘贴": [.en: "Paste", .th: "วาง"],
        "自动更新": [.en: "Auto update", .th: "อัปเดตอัตโนมัติ"],
        "每天": [.en: "Daily", .th: "รายวัน"],
        "每周": [.en: "Weekly", .th: "รายสัปดาห์"],
        "订阅并标注": [.en: "Subscribe & mark", .th: "สมัครและทำเครื่องหมาย"],
        "正在同步…": [.en: "Syncing…", .th: "กำลังซิงค์…"],
        "同步失败": [.en: "Sync failed", .th: "ซิงค์ล้มเหลว"],
        "同步失败 · 请检查网络或链接": [.en: "Sync failed · check network or URL", .th: "ซิงค์ล้มเหลว · ตรวจสอบเน็ตหรือลิงก์"],
        "中国大陆": [.en: "Mainland China", .th: "จีนแผ่นดินใหญ่"],
        "中国香港特别行政区": [.en: "Hong Kong SAR", .th: "ฮ่องกง"],
        "中国台湾": [.en: "Taiwan, China", .th: "ไต้หวัน"],
        "泰国": [.en: "Thailand", .th: "ประเทศไทย"],
        "officeholidays.com": [.en: "officeholidays.com", .th: "officeholidays.com"],
        "自定义 iCal 链接": [.en: "Custom iCal URL", .th: "ลิงก์ iCal เอง"],
        "国务院办公厅 · 官方公告": [.en: "State Council · official", .th: "คณะรัฐมนตรี · ทางการ"],
        "GovHK 官方日历": [.en: "GovHK official calendar", .th: "ปฏิทินทางการ GovHK"],
        "GovHK 公众假期": [.en: "GovHK public holidays", .th: "วันหยุด GovHK"],
        "行政院人事行政总处": [.en: "Executive Yuan DGPA", .th: "สำนักบริหารไต้หวัน"],
        "粘贴任意 .ics 订阅地址": [.en: "Paste any .ics URL", .th: "วางลิงก์ .ics ใดก็ได้"],
        "铁锈": [.en: "Rust", .th: "สนิม"],
        "石蓝": [.en: "Stone", .th: "สโตน"],
        "橄榄": [.en: "Olive", .th: "โอลีฟ"],
        "琥珀": [.en: "Amber", .th: "แอมเบอร์"],
        "绿": [.en: "Green", .th: "เขียว"]
    ]
}
