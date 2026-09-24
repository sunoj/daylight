// Compact workday marker, independent of lunar-date visibility.
import AppKit

enum CalendarWorkdayBadge {
    static func add(to view: NSView, color: NSColor) {
        let badge = UI.label(Loc.language == .zh || Loc.language == .zhHant ? "班" : "W", font: Typography.sans(8, .semibold), color: color)
        badge.toolTip = L("调休上班")
        badge.setAccessibilityLabel(L("调休上班"))
        badge.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: view.topAnchor, constant: 1),
            badge.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2)
        ])
    }
}
