// Background refresh of subscribed holiday feeds on the user's Daily/Weekly setting.
// Exports: HolidayRefresher
// Deps: Foundation, DaylightStore, HolidayService

import Foundation

final class HolidayRefresher {
    private let store: DaylightStore
    private let service: HolidayService
    private var inFlight = false

    init(store: DaylightStore) {
        self.store = store
        self.service = HolidayService(store: store)
    }

    static func isDue(lastSync: (date: Date, language: String)?, language: String, weekly: Bool, now: Date) -> Bool {
        guard let lastSync else { return true }
        if lastSync.language != language { return true }
        return now.timeIntervalSince(lastSync.date) >= (weekly ? 7 : 1) * 86_400
    }

    /// Fetches enabled subscriptions when the interval has passed. Nothing is
    /// requested while no holiday calendar is subscribed.
    func refreshIfDue(now: Date = Date(), onChange: @escaping () -> Void) {
        let settings = store.settings()
        guard !inFlight,
              settings.holidaySubscriptions.contains(where: \.enabled),
              Self.isDue(lastSync: store.holidaySyncStamp(), language: settings.language,
                         weekly: settings.holidayUpdateWeekly, now: now)
        else { return }
        inFlight = true
        Loc.language = AppLanguage(rawValue: settings.language) ?? .zh
        service.subscribe(subscriptions: settings.holidaySubscriptions) { [weak self] results in
            guard let self else { return }
            self.inFlight = false
            let synced = results.contains { if case .success = $0.result { return true } else { return false } }
            if synced {
                self.store.saveHolidaySyncStamp(now, language: settings.language)
                onChange()
            }
        }
    }
}
