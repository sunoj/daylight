// Settings screen — grouped rows (显示/日历/工具栏/数据/关于) plus quit action per redesign v2.
// Exports: CalendarSettingsPanel
// Deps: AppKit, DaylightStore, DesignSystem, Components

import AppKit
import UniformTypeIdentifiers

final class CalendarSettingsPanel: NSStackView {
    let store: DaylightStore
    let onDataChanged: () -> Void
    let onNeedsRender: () -> Void
    private let onClose: () -> Void
    private let onOpenStatusEditor: () -> Void
    private let onOpenHolidays: () -> Void
    private let onOpenSystemCalendar: () -> Void
    private let onToast: (String) -> Void
    private let launchAtLoginService = LaunchAtLoginService()

    init(
        store: DaylightStore,
        onDataChanged: @escaping () -> Void,
        onNeedsRender: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onOpenStatusEditor: @escaping () -> Void,
        onOpenHolidays: @escaping () -> Void,
        onOpenSystemCalendar: @escaping () -> Void,
        onToast: @escaping (String) -> Void
    ) {
        self.store = store
        self.onDataChanged = onDataChanged
        self.onNeedsRender = onNeedsRender
        self.onClose = onClose
        self.onOpenStatusEditor = onOpenStatusEditor
        self.onOpenHolidays = onOpenHolidays
        self.onOpenSystemCalendar = onOpenSystemCalendar
        self.onToast = onToast
        super.init(frame: .zero)
        orientation = .vertical
        spacing = 7
        alignment = .leading
        edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 6, right: 4)
        render()
    }

    required init?(coder: NSCoder) { nil }

    private func render() {
        let settings = store.settings()
        full(header())
        section(L("显示"))
        full(group([
            segmentedRow("square.grid.2x2", L("界面模式"), ["Luna", "Sol"], interfaceModeIndex(settings)) { [weak self] in self?.setInterfaceMode($0) },
            segmentedRow("globe", L("语言"), AppLanguage.allCases.map(\.displayName), languageIndex(settings)) { [weak self] in self?.setLanguage($0) },
            segmentedRow("circle.lefthalf.filled", L("外观"), [L("跟随"), L("浅"), L("深")], appearanceIndex(settings)) { [weak self] in self?.setAppearance($0) },
            toggleRow("drop.fill", L("显示农历"), lunarSettingIsOn(settings), #selector(toggleLunar)),
            toggleRow("calendar", L("显示周数"), settings.showWeekNumbers, #selector(toggleWeeks))
        ]))
        section(L("日历"))
        full(group([
            segmentedRow("calendar.badge.clock", L("每周起始日"), [L("周一"), L("周日")], settings.weekRule.firstWeekday == 1 ? 1 : 0) { [weak self] in self?.setWeekStart($0) },
            selectRow("globe", L("日历类型"), calendarTypeName(settings.weekRule), #selector(openCalendarTypeMenu(_:)))
        ]))
        section(L("工具栏"))
        // Launch-at-login controls the menu bar app's lifecycle, so it belongs
        // with menu bar behavior rather than display or calendar preferences.
        full(group([
            toggleRow("power", L("开机启动"), launchAtLoginService.isEnabled, #selector(toggleLaunchAtLogin)),
            navRow("menubar.rectangle", L("状态栏样式"), statusSummary(settings), #selector(openStatusEditor))
        ]))
        section(L("数据与同步"))
        full(group([
            navRow("calendar.badge.checkmark", L("系统日历"), systemCalendarSummary(settings), #selector(openSystemCalendar)),
            navRow("calendar.badge.plus", L("订阅节假日"), holidaySummary(settings), #selector(openHolidays)),
            actionRow("square.and.arrow.up", L("导出日记"), "\(store.allThoughts().count)", #selector(exportDiary))
        ]))
        section(L("关于"))
        var aboutRows = [valueRow("info.circle", L("版本"), Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0")]
        #if !APP_STORE
        aboutRows.append(actionRow("arrow.triangle.2.circlepath", L("检查更新"), "", #selector(checkForUpdates)))
        #endif
        full(group(aboutRows))
        full(group([
            destructiveActionRow("rectangle.portrait.and.arrow.right", L("退出 Daylight"), #selector(quitDaylight))
        ]))
    }

    // MARK: Structure

    private func full(_ view: NSView) {
        addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }

    private func section(_ title: String) {
        let header = UI.sectionHeader(title)
        addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }

    private func header() -> NSView {
        let title = UI.label(L("设置"), font: Typography.sans(20, .semibold), color: Palette.ink)
        let badge = pill("v2.0")
        let titleRow = NSStackView(views: [title, badge])
        titleRow.orientation = .horizontal
        titleRow.spacing = 9
        titleRow.alignment = .centerY
        let row = NSStackView(views: [titleRow, spacer(), closeButton()])
        row.orientation = .horizontal
        row.spacing = 8
        row.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return row
    }

    // MARK: Small parts

    private func pill(_ text: String) -> NSView {
        let box = UI.roundedBox(fill: .clear, radius: 999, border: Palette.line)
        let label = UI.label(text, font: Typography.mono(10), color: Palette.ink4)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: box.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -2),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 7),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -7)
        ])
        return box
    }

    private func closeButton() -> NSView {
        let button = RowButton(target: self, action: #selector(close))
        let tile = UI.roundedBox(fill: Palette.surface2, radius: 14)
        tile.widthAnchor.constraint(equalToConstant: 28).isActive = true
        tile.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let glyph = symbol("xmark", color: Palette.ink2)
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])
        button.addContentView(tile)
        return button
    }

    // MARK: Values

    private func appearanceIndex(_ settings: UserSettings) -> Int {
        switch settings.colorScheme {
        case "light": return 1
        case "dark": return 2
        default: return 0
        }
    }

    private func languageIndex(_ settings: UserSettings) -> Int {
        AppLanguage.allCases.firstIndex(of: AppLanguage(rawValue: settings.language) ?? .zh) ?? 0
    }

    private func statusSummary(_ settings: UserSettings) -> String {
        let names = settings.statusSegments.compactMap { StatusSegmentKind(rawValue: $0)?.displayName }
        return names.isEmpty ? L("无") : names.joined(separator: " · ")
    }

    private func holidaySummary(_ settings: UserSettings) -> String {
        let names = settings.holidaySubscriptions.filter(\.enabled).compactMap { HolidayService.preset($0.sourceId)?.name }
        return names.isEmpty ? L("未订阅") : names.map(L).joined(separator: " · ")
    }

    // MARK: Actions

    private func setLanguage(_ index: Int) {
        let lang = AppLanguage.allCases[index]
        update { $0.language = lang.rawValue }
    }

    private func setAppearance(_ index: Int) {
        let scheme = [0: "system", 1: "light", 2: "dark"][index] ?? "system"
        update { $0.colorScheme = scheme }
    }

    private func setWeekStart(_ index: Int) {
        update { $0.calendarType = (index == 1 ? CalendarWeekRule.us : .iso8601).rawValue }
    }

    @objc private func openStatusEditor() { onOpenStatusEditor() }
    @objc private func openHolidays() { onOpenHolidays() }
    @objc private func openSystemCalendar() { onOpenSystemCalendar() }
    @objc private func close() { onClose() }
    @objc private func quitDaylight() { NSApp.terminate(nil) }
    @objc private func toggleLunar(_ s: PillToggle) {
        update {
            if $0.isLunaUI {
                $0.lunaShowLunarDate = s.isOn
            } else {
                $0.showLunarDate = s.isOn
            }
        }
    }
    @objc private func toggleWeeks(_ s: PillToggle) { update { $0.showWeekNumbers = s.isOn } }

    @objc private func toggleLaunchAtLogin(_ sender: PillToggle) {
        do {
            try launchAtLoginService.setEnabled(sender.isOn)
        } catch {
            onToast(L("开机启动设置未生效"))
        }
        // The re-render re-reads SMAppService's status, so a rejected
        // registration (unsigned build, unapproved bundle) snaps the switch
        // back to what macOS actually thinks rather than leaving it lying.
        onNeedsRender()
    }

    @objc private func checkForUpdates() {
        Updater.shared.checkForUpdates()
    }

    @objc private func exportDiary() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "daylight-diary.json"
        panel.allowedContentTypes = [.json]
        // Menu bar app (LSUIElement): without activation the panel opens
        // behind other windows, and it must float above the closing popover.
        panel.level = .modalPanel
        NSApp.activate(ignoringOtherApps: true)
        // Snapshot the data now: presenting the panel closes the transient
        // popover and deallocates this panel view, so the completion must not
        // depend on self to do the actual writing.
        let diaries = store.allThoughts()
        let toast = onToast
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                try encoder.encode(diaries).write(to: url)
                toast(L("已导出"))
            } catch {
                toast(L("导出失败"))
            }
        }
    }

    func update(_ change: (inout UserSettings) -> Void) {
        var settings = store.settings()
        change(&settings)
        store.saveSettings(settings)
        onDataChanged()
        onNeedsRender()
    }
}
