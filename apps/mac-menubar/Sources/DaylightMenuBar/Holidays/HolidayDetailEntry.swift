// Holiday detail rows for Sol's selected-day agenda.
// Exports: HolidayDetailEntry, HolidayDetailEntries
// Deps: Foundation, DaylightStore, HolidayService

import Foundation

struct HolidayDetailEntry: Equatable {
    var day: PublicCalendarDay
    var colorId: String?
    var sourceId: String?
    var sourceName: String
    var isRemote: Bool
}

enum HolidayDetailEntries {
    static func entries(for date: LocalDate, store: DaylightStore) -> [HolidayDetailEntry] {
        entries(for: date, store: store, holidayHits: store.holidayHits(for: date))
    }

    static func entries(
        for date: LocalDate,
        store: DaylightStore,
        holidayHits: [(subscription: HolidaySubscription, day: PublicCalendarDay)]
    ) -> [HolidayDetailEntry] {
        let subscriptionEntries = holidayHits.map { hit in
            HolidayDetailEntry(
                day: hit.day,
                colorId: hit.subscription.colorId,
                sourceId: hit.subscription.sourceId,
                sourceName: sourceName(for: hit.subscription),
                isRemote: false
            )
        }
        let subscriptionNames = Set(subscriptionEntries.compactMap { normalizedName($0.day.name) })
        let remoteEntries = store.publicDays()
            .filter { $0.date == date.key }
            .filter { day in
                guard let name = normalizedName(day.name) else { return true }
                return !subscriptionNames.contains(name)
            }
            .map { day in
                HolidayDetailEntry(day: day, colorId: nil, sourceId: nil, sourceName: "同步", isRemote: true)
            }
        return subscriptionEntries + remoteEntries
    }

    private static func sourceName(for subscription: HolidaySubscription) -> String {
        if subscription.sourceId == "custom" {
            let name = subscription.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? "自定义 iCal 链接" : name
        }
        let sourceId = subscription.sourceId
        return HolidayService.preset(sourceId)?.name ?? (sourceId == "custom" ? "自定义 iCal 链接" : sourceId)
    }

    private static func normalizedName(_ name: String?) -> String? {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
