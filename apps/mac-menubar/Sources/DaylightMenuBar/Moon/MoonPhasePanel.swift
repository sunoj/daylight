// Simple moon row — flat disc + date-only phase info (no location).
// Exports: MoonPhasePanel
// Deps: AppKit, MoonObservationCalculator, LunarCalendar, DesignSystem

import AppKit

/// A location-free moon summary. Phase, illumination, and age are computed
/// from the date alone; opening the 3D model (which needs location) is a
/// separate feature. Shown as a tappable row with a trailing chevron.
final class MoonPhasePanel: NSView {
    private let displayDate: LocalDate
    private let showLunarSuffix: Bool
    private let disc = MoonDiscView(frame: .zero)
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let calculator = MoonObservationCalculator()
    private let lunarCalendar = LunarCalendar()
    private let reference = ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)

    init(displayDate: LocalDate, showLunarSuffix: Bool = true, frame frameRect: NSRect = .zero) {
        self.displayDate = displayDate
        self.showLunarSuffix = showLunarSuffix
        super.init(frame: frameRect)
        configureLayout()
        update()
    }

    required init?(coder: NSCoder) { nil }

    private func configureLayout() {
        disc.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = Typography.sans(14, .semibold)
        titleLabel.textColor = Palette.ink
        detailLabel.font = Typography.mono(11)
        detailLabel.textColor = Palette.ink3
        detailLabel.maximumNumberOfLines = 1

        let text = NSStackView(views: [titleLabel, detailLabel])
        text.orientation = .vertical
        text.spacing = 3
        text.alignment = .leading

        let chevron = NSImageView(image: NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil) ?? NSImage())
        chevron.contentTintColor = Palette.ink4

        let stack = NSStackView(views: [disc, text, spacer(), chevron])
        stack.orientation = .horizontal
        stack.spacing = 14
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            disc.widthAnchor.constraint(equalToConstant: 44),
            disc.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private func update() {
        let observation = calculator.observation(at: displayDate.noonDate, location: reference)
        disc.fraction = observation.illuminatedFraction
        disc.waxing = observation.phaseAngleDegrees < 180
        titleLabel.stringValue = "\(MoonNames.phaseCN(observation.phaseAngleDegrees))\(lunarSuffix())"
        let percent = Int((observation.illuminatedFraction * 100).rounded())
        detailLabel.stringValue = "\(percent)% 照亮 · 月龄 \(String(format: "%.1f", observation.ageDays))d"
    }

    private func lunarSuffix() -> String {
        guard showLunarSuffix, let lunar = lunarCalendar.lunarDate(for: displayDate) else { return "" }
        return " · \(lunar.monthName)月\(lunar.dayName)"
    }
}

/// Shared Chinese phase names keyed by phase angle (0 = new, 180 = full).
enum MoonNames {
    static func phaseCN(_ angle: Double) -> String {
        switch angle {
        case 0..<22.5, 337.5..<360: return L("新月")
        case 22.5..<67.5: return L("娥眉月")
        case 67.5..<112.5: return L("上弦月")
        case 112.5..<157.5: return L("盈凸月")
        case 157.5..<202.5: return L("满月")
        case 202.5..<247.5: return L("亏凸月")
        case 247.5..<292.5: return L("下弦月")
        default: return L("残月")
        }
    }
}
