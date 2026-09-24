// Diary thought model, id/timestamp helpers, and legacy payload migration.
// Exports: DiaryThought, DiaryThoughtDraft, DiaryThoughtCodec
// Deps: Foundation

import Foundation

struct DiaryThought: Codable, Hashable {
    var id: String
    var date: String
    var content: String
    var createdAt: String
    var updatedAt: String
    var done: Bool? = nil
}

struct DiaryThoughtDraft: Equatable {
    let content: String
    let done: Bool?
}

enum DiaryThoughtCodec {
    static func timestamp(from date: Date = Date()) -> String {
        DiaryThoughtCodec.formatter.string(from: date)
    }

    static func newId() -> String {
        UUID().uuidString
    }

    static func parseInput(_ raw: String) -> DiaryThoughtDraft? {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        let markers: [(prefix: String, done: Bool)] = [
            ("[]", false),
            ("[ ]", false),
            ("[x]", true),
            ("[X]", true)
        ]
        for marker in markers where input.hasPrefix(marker.prefix) {
            let content = String(input.dropFirst(marker.prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { return nil }
            return DiaryThoughtDraft(content: content, done: marker.done)
        }
        return DiaryThoughtDraft(content: input, done: nil)
    }

    static func legacyId(for date: String) -> String {
        "legacy-\(date)"
    }

    static func decodeStoredPayload(_ data: Data) -> [DiaryThought] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return [] }
        guard let array = json as? [Any] else { return [] }
        return array.compactMap(decodeItem)
    }

    static func decodeItem(_ value: Any) -> DiaryThought? {
        guard let record = value as? [String: Any],
              let date = record["date"] as? String,
              let content = record["content"] as? String else { return nil }
        let updatedAt = (record["updatedAt"] as? String) ?? timestamp()
        let done = record["done"] as? Bool
        if let id = record["id"] as? String, let createdAt = record["createdAt"] as? String {
            return DiaryThought(id: id, date: date, content: content, createdAt: createdAt, updatedAt: updatedAt, done: done)
        }
        return DiaryThought(
            id: legacyId(for: date),
            date: date,
            content: content,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            done: done
        )
    }

    /// Ties broken by id so the order is deterministic. Two thoughts saved in
    /// the same millisecond share a createdAt, and without a tie-break their
    /// order flipped between reads — visibly, if you type two in quick
    /// succession.
    static func sortedNewestFirst(_ thoughts: [DiaryThought]) -> [DiaryThought] {
        thoughts.sorted {
            $0.createdAt == $1.createdAt ? $0.id > $1.id : $0.createdAt > $1.createdAt
        }
    }

    /// Oldest at the top of the stack so the newest row sits just above the input.
    static func sortedOldestFirst(_ thoughts: [DiaryThought]) -> [DiaryThought] {
        thoughts.sorted {
            $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt < $1.createdAt
        }
    }

    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
