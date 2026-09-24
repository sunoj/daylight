// Text-safe moon phase backdrop for today's date in the Luna calendar.
// Deps: AppKit, MoonArt, MoonObservationCalculator, DesignSystem

import AppKit

final class TodayMoonBackgroundView: NSView {
    let fraction: Double
    let waxing: Bool

    init(date: LocalDate) {
        let moon = MoonObservationCalculator().observation(
            at: date.noonDate,
            location: ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)
        )
        fraction = moon.illuminatedFraction
        waxing = moon.phaseAngleDegrees < 180
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    // The backdrop must not intercept date selection.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let diameter = min(bounds.width, bounds.height)
        let disc = CGRect(x: bounds.midX - diameter / 2, y: bounds.midY - diameter / 2,
                          width: diameter, height: diameter)
        context.setFillColor(cg(Palette.todayMoonShadow))
        context.fillEllipse(in: disc)
        context.addPath(MoonArt.illuminatedPath(fraction: fraction, waxing: waxing, in: disc))
        context.setFillColor(cg(Palette.todayMoonLit))
        context.fillPath()
    }
}
