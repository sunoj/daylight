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
    private var refreshTimer: Timer?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        refreshStatusTitle()
        // No-op in unbundled dev builds; in release bundles this arms
        // Sparkle's scheduled background update checks.
        Updater.shared.start()
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 600,
            repeats: true,
            block: { [weak self] _ in self?.refreshStatusTitle() }
        )
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }
        button.target = self
        button.action = #selector(togglePopover)
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

    private func refreshStatusTitle() {
        guard let button = statusItem.button else { return }
        let settings = store.settings()
        Loc.language = AppLanguage(rawValue: settings.language) ?? .zh
        let segments = statusTitleProvider.segments(today: calendarModel.today(), settings: settings)
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

}
