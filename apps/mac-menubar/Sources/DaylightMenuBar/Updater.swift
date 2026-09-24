// Sparkle in-app updater bridge, mirroring the sibling project (CMView):
// Sparkle.framework is loaded dynamically from the app bundle at startup.
// When the binary runs unbundled (swift run / install-local.sh) the framework
// is absent and every call no-ops, so the dev loop doesn't need Sparkle.
//
// Release builds get Sparkle.framework copied into Contents/Frameworks/ by
// scripts/release-macos.sh, plus SUFeedURL / SUPublicEDKey baked into
// Info.plist — Sparkle reads both at controller-init time.

import AppKit

#if APP_STORE
final class Updater {
    static let shared = Updater()
    func start() {}
    @discardableResult func checkForUpdates() -> Bool { false }
}
#else
final class Updater {
    static let shared = Updater()

    /// Fallback download page when Sparkle isn't loaded (dev builds, or a
    /// bundle missing the framework).
    static let downloadURL = "https://github.com/sunoj/daylight/releases/latest"

    private var controller: NSObject?
    private var attempted = false

    /// Load Sparkle.framework (if present) and create the standard updater
    /// controller. Safe to call repeatedly; only the first call does work.
    func start() {
        guard !attempted else { return }
        attempted = true
        guard let frameworksPath = Bundle.main.privateFrameworksPath else { return }
        let path = frameworksPath + "/Sparkle.framework"
        guard let bundle = Bundle(path: path), bundle.load() else { return }
        guard let cls = NSClassFromString("SPUStandardUpdaterController") as? NSObject.Type else { return }
        // SPUStandardUpdaterController's designated programmatic init is
        // -initWithUpdaterDelegate:userDriverDelegate: (plain -init is
        // NS_UNAVAILABLE and yields a no-op controller). nil delegates fall
        // back to the default user driver (standard update UI).
        guard let allocated = cls.perform(Selector(("alloc")))?.takeUnretainedValue() as? NSObject else { return }
        let initSelector = Selector(("initWithUpdaterDelegate:userDriverDelegate:"))
        controller = allocated.perform(initSelector, with: nil, with: nil)?.takeRetainedValue() as? NSObject
    }

    /// User-triggered "Check for Updates…". Returns true if dispatched to
    /// Sparkle, false if running unbundled (then shows a fallback dialog).
    @discardableResult
    func checkForUpdates() -> Bool {
        start()
        if let controller {
            controller.perform(Selector(("checkForUpdates:")), with: nil)
            return true
        }
        showUnavailableFallback()
        return false
    }

    private func showUnavailableFallback() {
        let alert = NSAlert()
        alert.messageText = L("此构建不包含自动更新")
        alert.informativeText = L("本地构建未包含自动更新组件。前往下载页面获取最新版本？")
        alert.addButton(withTitle: L("前往下载"))
        alert.addButton(withTitle: L("取消"))
        if alert.runModal() == .alertFirstButtonReturn, let url = URL(string: Self.downloadURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
#endif
