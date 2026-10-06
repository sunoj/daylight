// AppKit application delegate for status item and popover lifecycle.
// Exports: AppDelegate
// Deps: AppKit, DaylightStore, CalendarModel, PopoverViewController, StatusTitleProvider

import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let store = DaylightStore()
    private let calendarModel = CalendarModel()
    private let statusTitleProvider = StatusTitleProvider()
    private lazy var holidayRefresher = HolidayRefresher(store: store)
    private var refreshTimer: Timer?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.make()
        configureStatusItem()
        configurePopover()
        refreshStatusTitle()
        DispatchQueue.main.async { [weak self] in self?.prewarmPopover() }
        // No-op in unbundled dev builds; in release bundles this arms
        // Sparkle's scheduled background update checks.
        Updater.shared.start()
        scheduleMinuteRefresh()
        observeClockChanges()
        refreshHolidaysIfDue()
    }

    /// Opening the app again from Finder or Launchpad shows the popover, so a
    /// menu bar item hidden behind the notch still leaves a way in.
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !popover.isShown { togglePopover() }
        return false
    }

    /// The menu bar can show the time, so redraw on every minute boundary.
    private func scheduleMinuteRefresh() {
        let timer = Timer(fireAt: Self.nextMinute(after: Date()), interval: 60, target: self,
                          selector: #selector(minuteTick), userInfo: nil, repeats: true)
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    static func nextMinute(after date: Date) -> Date {
        let seconds = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (seconds / 60).rounded(.down) * 60 + 60)
    }

    private func observeClockChanges() {
        let center = NotificationCenter.default
        for name in [Notification.Name.NSCalendarDayChanged, .NSSystemClockDidChange, .NSSystemTimeZoneDidChange] {
            center.addObserver(self, selector: #selector(clockChanged), name: name, object: nil)
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(clockChanged), name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    @objc private func minuteTick() {
        refreshStatusTitle()
        refreshHolidaysIfDue()
    }

    @objc private func clockChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Timers drift across sleep and clock changes; re-arm on the boundary.
            self.refreshTimer?.invalidate()
            self.scheduleMinuteRefresh()
            self.refreshStatusTitle()
            self.refreshHolidaysIfDue()
        }
    }

    private func refreshHolidaysIfDue() {
        holidayRefresher.refreshIfDue { [weak self] in
            self?.refreshStatusTitle()
            (self?.popover.contentViewController as? PopoverViewController)?.render()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }
        button.target = self
        button.action = #selector(togglePopover)
        button.setAccessibilityRole(.button)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 396, height: 560)
        popover.contentViewController = PopoverViewController(
            store: store,
            calendarModel: calendarModel,
            onDataChanged: { [weak self] in self?.refreshStatusTitle() }
        )
    }

    /// Builds the popover's view tree once the launch has settled, so the first
    /// click only has to show it. Loaded on demand, that click paid for font
    /// registration, lunar tables and the first layout: 270–770ms cold.
    private func prewarmPopover() {
        popover.contentViewController?.view.layoutSubtreeIfNeeded()
    }

    private func refreshStatusTitle() {
        guard let button = statusItem.button else { return }
        let settings = store.settings()
        Loc.language = AppLanguage(rawValue: settings.language) ?? .zh
        let segments = statusTitleProvider.segments(today: calendarModel.today(), settings: settings)
        // The item is image-only; VoiceOver needs words.
        button.setAccessibilityLabel("\(L("昼间日历")) · \(Loc.monthTitle(year: calendarModel.today().year, month: calendarModel.today().month)) \(calendarModel.today().day)")
        if let image = StatusBarRenderer.image(for: segments) {
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.image = nil
            button.imagePosition = .noImage
            button.title = String(calendarModel.today().day)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            (popover.contentViewController as? PopoverViewController)?.refreshForPresentation()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

}
