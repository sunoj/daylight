// Pure extraction of supported video-conference links from event metadata.
// Exports: VideoLinkDetector
// Deps: Foundation, NSDataDetector

import Foundation

enum VideoLinkDetector {
    private static let hosts = [
        "zoom.us",
        "meet.google.com",
        "teams.microsoft.com",
        "webex.com",
        "whereby.com",
        "chime.aws",
        "bluejeans.com"
    ]

    static func detect(url: URL?, notes: String?, location: String?) -> URL? {
        if let url, isSupported(url) { return url }
        if let location, let match = firstSupportedLink(in: location) { return match }
        if let notes, let match = firstSupportedLink(in: notes) { return match }
        return nil
    }

    private static func firstSupportedLink(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var match: URL?
        detector.enumerateMatches(in: text, options: [], range: range) { result, _, stop in
            guard match == nil, let candidate = result?.url, isSupported(candidate) else { return }
            match = candidate
            stop.pointee = true
        }
        return match
    }

    private static func isSupported(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return hosts.contains { host.contains($0) }
    }
}
