// Interface-mode and system-calendar settings rows.
// Exports: CalendarSettingsPanel system-calendar actions
// Deps: AppKit, DaylightStore, SystemCalendarService, Localization

import AppKit

extension CalendarSettingsPanel {
    func interfaceModeIndex(_ settings: UserSettings) -> Int {
        settings.isLunaUI ? 0 : 1
    }

    func lunarSettingIsOn(_ settings: UserSettings) -> Bool {
        settings.isLunaUI ? settings.lunaShowLunarDate : settings.showLunarDate
    }

    func setInterfaceMode(_ index: Int) {
        update { $0.uiMode = index == 0 ? "luna" : "sol" }
    }

    func systemCalendarSummary(_ settings: UserSettings) -> String {
        guard settings.systemCalendarEnabled else { return L("无") }
        switch SystemCalendarService.shared.authorization {
        case .authorized:
            let counts = SystemCalendarService.shared.calendarCounts(hiddenIds: settings.hiddenCalendarIds)
            return "\(counts.visible) / \(counts.total) \(L("个日历"))"
        case .notDetermined, .denied, .restricted:
            return L("未授权")
        }
    }
}
