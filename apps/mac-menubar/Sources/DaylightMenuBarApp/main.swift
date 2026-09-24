// macOS application entry point for the Daylight menu bar client.
// Exports: process bootstrap through NSApplication
// Deps: AppKit, DaylightMenuBarKit AppDelegate

import AppKit
import DaylightMenuBarKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
