// Locates the SwiftPM resource bundle without SwiftPM's crashing accessor.
// Exports: ResourceBundle
// Deps: Foundation Bundle

import Foundation

/// SwiftPM's generated `Bundle.module` only looks beside the `.app` (not in
/// `Contents/Resources`) and then at an absolute `.build` path on the machine
/// that compiled it, calling `fatalError` when both miss. A packaged app on any
/// other Mac takes that branch, so use this lookup everywhere instead.
enum ResourceBundle {
    static let name = "DaylightMenuBar_DaylightMenuBarKit.bundle"

    static let kit: Bundle? = locate(mainBundle: .main)

    static func locate(mainBundle: Bundle) -> Bundle? {
        let candidates = [
            mainBundle.resourceURL?.appendingPathComponent(name),
            mainBundle.bundleURL.appendingPathComponent(name)
        ]
        for case let url? in candidates {
            if let bundle = Bundle(url: url) { return bundle }
        }
        // Only unpackaged runs (swift run, swift test) may use SwiftPM's
        // build-path fallback; a shipped .app must degrade, never trap.
        guard mainBundle.bundleURL.pathExtension != "app" else { return nil }
        return Bundle.module
    }
}
