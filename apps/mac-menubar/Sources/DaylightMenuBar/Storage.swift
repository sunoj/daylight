// UserDefaults-backed persistence for the native menu bar client.
// Exports: DaylightStore, UserSettings, DiaryThought, CachedObserverLocation
// Deps: Foundation JSONEncoder and UserDefaults
import Foundation

struct HolidaySubscription: Codable, Hashable {
    var id, sourceId, customURL, colorId: String
    var enabled: Bool
    var name: String = ""
}

extension HolidaySubscription {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: try c.decodeIfPresent(String.self, forKey: .id) ?? "",
                  sourceId: try c.decodeIfPresent(String.self, forKey: .sourceId) ?? "",
                  customURL: try c.decodeIfPresent(String.self, forKey: .customURL) ?? "",
                  colorId: try c.decodeIfPresent(String.self, forKey: .colorId) ?? "",
                  enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false,
                  name: try c.decodeIfPresent(String.self, forKey: .name) ?? "")
    }
}

struct UserSettings: Codable {
    var language: String = AppLanguage.systemDefault.rawValue
    var colorScheme: String = "system"
    var showLunarDate: Bool = true
    var showWeekNumbers: Bool = true
    var calendarType: String = CalendarWeekRule.iso8601.rawValue
    // Luna/Sol settings default existing users to the compact screen.
    var uiMode: String = "luna"
    var lunaShowLunarDate: Bool = false
    var systemCalendarEnabled: Bool = true
    var hiddenCalendarIds: [String] = []
    // Menu bar status item: an ordered list of rendered segments plus format.
    // Segment ids: "moon" | "dateBox" | "gregorian" | "lunar" | "weekday" | "time"
    var statusSegments: [String] = ["moon", "lunar"]
    var statusUse24HourTime: Bool = true

    // Legal-holiday subscriptions (iCal).
    var holidaySubscriptions: [HolidaySubscription] = []
    var holidayUpdateWeekly: Bool = false

    var weekRule: CalendarWeekRule {
        CalendarWeekRule(rawValue: calendarType) ?? .iso8601
    }
    var isLunaUI: Bool { uiMode == "luna" }
}
extension UserSettings {
    enum CodingKeys: String, CodingKey {
        case language, colorScheme, showLunarDate, showWeekNumbers, calendarType
        case uiMode, lunaShowLunarDate, minimalShowLunar, systemCalendarEnabled, hiddenCalendarIds
        case statusSegments, statusUse24HourTime
        case holidaySubscriptions, holidayUpdateWeekly
        case holidaySource, holidayURL, holidaySubscribed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = UserSettings()
        let subscriptions = try container.decodeIfPresent([HolidaySubscription].self, forKey: .holidaySubscriptions)
        let legacySource = try container.decodeIfPresent(String.self, forKey: .holidaySource) ?? "cn"
        let legacyURL = try container.decodeIfPresent(String.self, forKey: .holidayURL) ?? ""
        let legacySubscribed = try container.decodeIfPresent(Bool.self, forKey: .holidaySubscribed) ?? false
        let migratedMode: String
        switch try container.decodeIfPresent(String.self, forKey: .uiMode) {
        case "luna", "minimal": migratedMode = "luna"
        case "sol", "full": migratedMode = "sol"
        default: migratedMode = defaults.uiMode
        }
        let migratedLunaShowLunarDate = try container.decodeIfPresent(Bool.self, forKey: .lunaShowLunarDate)
            ?? (try container.decodeIfPresent(Bool.self, forKey: .minimalShowLunar))
            ?? defaults.lunaShowLunarDate
        self.init(
            language: try container.decodeIfPresent(String.self, forKey: .language) ?? defaults.language,
            colorScheme: try container.decodeIfPresent(String.self, forKey: .colorScheme) ?? defaults.colorScheme,
            showLunarDate: try container.decodeIfPresent(Bool.self, forKey: .showLunarDate) ?? defaults.showLunarDate,
            showWeekNumbers: try container.decodeIfPresent(Bool.self, forKey: .showWeekNumbers) ?? defaults.showWeekNumbers,
            calendarType: try container.decodeIfPresent(String.self, forKey: .calendarType) ?? defaults.calendarType,
            uiMode: migratedMode,
            lunaShowLunarDate: migratedLunaShowLunarDate,
            systemCalendarEnabled: try container.decodeIfPresent(Bool.self, forKey: .systemCalendarEnabled) ?? defaults.systemCalendarEnabled,
            hiddenCalendarIds: try container.decodeIfPresent([String].self, forKey: .hiddenCalendarIds) ?? defaults.hiddenCalendarIds,
            statusSegments: try container.decodeIfPresent([String].self, forKey: .statusSegments) ?? defaults.statusSegments,
            statusUse24HourTime: try container.decodeIfPresent(Bool.self, forKey: .statusUse24HourTime) ?? defaults.statusUse24HourTime,
            holidaySubscriptions: subscriptions ?? (legacySubscribed ? [
                HolidaySubscription(id: "legacy-\(legacySource)", sourceId: legacySource, customURL: legacyURL, colorId: "rust", enabled: true)
            ] : defaults.holidaySubscriptions),
            holidayUpdateWeekly: try container.decodeIfPresent(Bool.self, forKey: .holidayUpdateWeekly) ?? defaults.holidayUpdateWeekly
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(colorScheme, forKey: .colorScheme)
        try container.encode(showLunarDate, forKey: .showLunarDate)
        try container.encode(showWeekNumbers, forKey: .showWeekNumbers)
        try container.encode(calendarType, forKey: .calendarType)
        try container.encode(uiMode, forKey: .uiMode)
        try container.encode(lunaShowLunarDate, forKey: .lunaShowLunarDate)
        try container.encode(systemCalendarEnabled, forKey: .systemCalendarEnabled)
        try container.encode(hiddenCalendarIds, forKey: .hiddenCalendarIds)
        try container.encode(statusSegments, forKey: .statusSegments)
        try container.encode(statusUse24HourTime, forKey: .statusUse24HourTime)
        try container.encode(holidaySubscriptions, forKey: .holidaySubscriptions)
        try container.encode(holidayUpdateWeekly, forKey: .holidayUpdateWeekly)
    }
}
struct PublicCalendarDay: Codable, Hashable {
    var date: String
    var type: String
    var name: String? = nil
    var description: String? = nil
    var sourceUrl: String? = nil
    var isImportant: Bool
}
struct CachedObserverLocation: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date

    init(latitude: Double, longitude: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }

    init(location: ObserverLocation, timestamp: Date) {
        self.init(latitude: location.latitudeDegrees, longitude: location.longitudeDegrees, timestamp: timestamp)
    }

    var observerLocation: ObserverLocation {
        ObserverLocation(latitudeDegrees: latitude, longitudeDegrees: longitude)
    }
}
extension PublicCalendarDay {
    // `isImportant` is optional in the feed (TS defaults it to false); a custom
    // decoder keeps a payload that omits it from dropping the whole array.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            date: try container.decode(String.self, forKey: .date),
            type: try container.decode(String.self, forKey: .type),
            name: try container.decodeIfPresent(String.self, forKey: .name),
            description: try container.decodeIfPresent(String.self, forKey: .description),
            sourceUrl: try container.decodeIfPresent(String.self, forKey: .sourceUrl),
            isImportant: try container.decodeIfPresent(Bool.self, forKey: .isImportant) ?? false
        )
    }
}

final class DaylightStore {
    private struct CacheEntry {
        let data: Data
        let value: Any
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cache: [String: CacheEntry] = [:]
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    func settings() -> UserSettings {
        read(UserSettings.self, key: "settings") ?? UserSettings()
    }
    func saveSettings(_ settings: UserSettings) {
        write(settings, key: "settings")
    }
    func thoughts(for date: LocalDate) -> [DiaryThought] {
        DiaryThoughtCodec.sortedNewestFirst(diaryThoughts().filter { $0.date == date.key })
    }

    func allThoughts() -> [DiaryThought] {
        diaryThoughts().sorted {
            if $0.date == $1.date { return $0.createdAt < $1.createdAt }
            return $0.date < $1.date
        }
    }

    func addThought(for date: LocalDate, content: String, done: Bool? = nil) {
        let now = DiaryThoughtCodec.timestamp()
        let thought = DiaryThought(
            id: DiaryThoughtCodec.newId(),
            date: date.key,
            content: content,
            createdAt: now,
            updatedAt: now,
            done: done
        )
        write(diaryThoughts() + [thought], key: "diaryEntries")
    }

    func toggleThought(id: String) {
        var thoughts = diaryThoughts()
        guard let index = thoughts.firstIndex(where: { $0.id == id }), let done = thoughts[index].done else { return }
        thoughts[index].done = !done
        thoughts[index].updatedAt = DiaryThoughtCodec.timestamp()
        write(thoughts, key: "diaryEntries")
    }

    func deleteThought(id: String) {
        write(diaryThoughts().filter { $0.id != id }, key: "diaryEntries")
    }

    /// Remote public days and iCal-subscribed holidays are stored separately and
    /// merged here (subscription wins) so the two sync paths don't clobber.
    func publicDay(for date: LocalDate) -> PublicCalendarDay? {
        holidayHits(for: date).first?.day ?? publicDays().first { $0.date == date.key }
    }
    func publicDays() -> [PublicCalendarDay] {
        read([PublicCalendarDay].self, key: "publicDays") ?? []
    }
    func replacePublicDays(_ days: [PublicCalendarDay]) {
        write(days, key: "publicDays")
    }
    func holidayDays() -> [PublicCalendarDay] {
        let bySubscription = holidayDaysBySubscription()
        let subscriptions = settings().holidaySubscriptions
        if !bySubscription.isEmpty {
            return subscriptions.flatMap { bySubscription[$0.id] ?? [] }
        }
        return subscriptions.isEmpty ? [] : (read([PublicCalendarDay].self, key: "holidayDays") ?? [])
    }
    func holidayHits(for date: LocalDate) -> [(subscription: HolidaySubscription, day: PublicCalendarDay)] {
        let bySubscription = holidayDaysBySubscription()
        let subscriptions = settings().holidaySubscriptions.filter(\.enabled)
        if bySubscription.isEmpty, subscriptions.count == 1 {
            return (read([PublicCalendarDay].self, key: "holidayDays") ?? [])
                .filter { $0.date == date.key }
                .map { (subscriptions[0], $0) }
        }
        return subscriptions.flatMap { subscription in
            (bySubscription[subscription.id] ?? []).filter { $0.date == date.key }.map { (subscription, $0) }
        }
    }
    func replaceHolidayDays(_ days: [PublicCalendarDay], for subscriptionId: String) {
        var bySubscription = holidayDaysBySubscription()
        bySubscription[subscriptionId] = days
        write(bySubscription, key: "holidayDaysBySubscription")
    }
    func removeHolidayDays(for subscriptionId: String) {
        var bySubscription = holidayDaysBySubscription()
        bySubscription.removeValue(forKey: subscriptionId)
        write(bySubscription, key: "holidayDaysBySubscription")
    }
    func cachedObserverLocation() -> CachedObserverLocation? {
        read(CachedObserverLocation.self, key: "observerLocation")
    }
    func saveObserverLocation(_ location: ObserverLocation, timestamp: Date = Date()) {
        write(CachedObserverLocation(location: location, timestamp: timestamp), key: "observerLocation")
    }
    func clearObserverLocation() {
        defaults.removeObject(forKey: "observerLocation")
        invalidateCache(for: "observerLocation")
    }

    private func diaryThoughts() -> [DiaryThought] {
        guard let data = defaults.data(forKey: "diaryEntries") else {
            invalidateCache(for: "diaryEntries")
            return []
        }
        if let entry = cache["diaryEntries"], entry.data == data, let value = entry.value as? [DiaryThought] {
            return value
        }
        let thoughts = DiaryThoughtCodec.decodeStoredPayload(data)
        cache["diaryEntries"] = CacheEntry(data: data, value: thoughts)
        return thoughts
    }

    private func holidayDaysBySubscription() -> [String: [PublicCalendarDay]] {
        read([String: [PublicCalendarDay]].self, key: "holidayDaysBySubscription") ?? [:]
    }

    private func read<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else {
            invalidateCache(for: key)
            return nil
        }
        if let entry = cache[key], entry.data == data, let value = entry.value as? T {
            return value
        }
        guard let value = try? decoder.decode(type, from: data) else { return nil }
        cache[key] = CacheEntry(data: data, value: value)
        return value
    }

    private func write<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
        cache[key] = CacheEntry(data: data, value: value)
    }

    private func invalidateCache(for key: String) {
        cache.removeValue(forKey: key)
    }
}
