// Compact selected-date moon phase readout for the Luna agenda title.
// Exports: CompactMoonReadout
// Deps: AppKit, MoonObservationCalculator, MoonDiscView, DesignSystem, Components, ViewPrimitives

import AppKit

final class CompactMoonReadout: RowButton {
    private let disc = MoonDiscView(frame: .zero)
    private let calculator = MoonObservationCalculator()
    private let reference = ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)

    init(date: LocalDate, target: AnyObject?, action: Selector) {
        super.init(target: target, action: action)

        let observation = calculator.observation(at: date.noonDate, location: reference)
        disc.fraction = observation.illuminatedFraction
        disc.waxing = observation.phaseAngleDegrees < 180
        disc.outlineColor = Palette.eventInk3

        let name = UI.label(
            MoonNames.phaseCN(observation.phaseAngleDegrees),
            font: Typography.sans(11.5),
            color: Palette.eventInk2
        )
        // Protect the phase label when the adjacent solar-term icon is present.
        name.setContentCompressionResistancePriority(.required, for: .horizontal)
        let textWidth = (name.stringValue as NSString).size(withAttributes: [.font: name.font!]).width
        name.widthAnchor.constraint(greaterThanOrEqualToConstant: ceil(textWidth) + 6).isActive = true
        let row = NSStackView(views: [disc, name])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 5
        row.translatesAutoresizingMaskIntoConstraints = false
        addContentView(row)
        NSLayoutConstraint.activate([
            disc.widthAnchor.constraint(equalToConstant: 15),
            disc.heightAnchor.constraint(equalToConstant: 15)
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) { nil }
}
