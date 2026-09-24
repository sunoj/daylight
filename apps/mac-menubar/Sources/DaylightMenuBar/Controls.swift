// Interactive controls for the plain design system.
// Exports: PillToggle, SegmentedControl
// Deps: AppKit, DesignSystem, ViewPrimitives

import AppKit

/// A 42×25 pill switch: off = surface-3 track with a light knob on the left,
/// on = ink track with a paper knob on the right.
final class PillToggle: NSControl {
    private(set) var isOn: Bool
    private let track = CALayer()
    private let knob = CALayer()

    init(isOn: Bool, target: AnyObject?, action: Selector) {
        self.isOn = isOn
        super.init(frame: NSRect(x: 0, y: 0, width: 42, height: 25))
        self.target = target
        self.action = action
        wantsLayer = true
        layer?.addSublayer(track)
        track.addSublayer(knob)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 42).isActive = true
        heightAnchor.constraint(equalToConstant: 25).isActive = true
        apply(animated: false)
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        apply(animated: false)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        apply(animated: false)
    }

    override func mouseDown(with event: NSEvent) {
        activate()
    }

    /// Toggle + animate + fire the action. Row containers call this so the
    /// whole settings row acts as the toggle's hit area, not just the pill.
    func activate() {
        isOn.toggle()
        apply(animated: true)
        sendAction(action, to: target)
    }

    private func apply(animated: Bool) {
        let oldTrackColor = track.presentation()?.backgroundColor ?? track.backgroundColor
        let oldKnobPosition = knob.presentation()?.position ?? knob.position
        let fill = cg(isOn ? Palette.ink : Palette.surface3)
        let knobFill = cg(isOn ? Palette.accentInk : Palette.surface)
        let inset: CGFloat = 2.5
        let diameter = bounds.height - inset * 2
        let x = isOn ? bounds.width - diameter - inset : inset
        let knobFrame = CGRect(x: x, y: inset, width: diameter, height: diameter)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        track.frame = bounds
        track.cornerRadius = bounds.height / 2
        track.backgroundColor = fill
        knob.frame = knobFrame
        knob.cornerRadius = diameter / 2
        knob.backgroundColor = knobFill
        if !isOn {
            knob.shadowColor = cg(Palette.shadow)
            knob.shadowOpacity = 0.12
            knob.shadowRadius = 1
            knob.shadowOffset = CGSize(width: 0, height: -0.5)
        } else {
            knob.shadowOpacity = 0
        }
        CATransaction.commit()

        guard animated else { return }
        Motion.animate(track, keyPath: "backgroundColor", from: oldTrackColor, to: fill, duration: Motion.quick, timing: Motion.easeOut)
        Motion.animate(knob, keyPath: "position", from: oldKnobPosition, to: knob.position, duration: Motion.quick, timing: Motion.emphasis)
    }
}

/// A pill segmented control (跟随/浅/深, 周一/周日). Reports the chosen index.
final class SegmentedControl: NSView {
    private let onChange: (Int) -> Void
    private var index: Int
    private var segments: [NSView] = []
    private var labels: [NSTextField] = []

    init(items: [String], selectedIndex: Int, onChange: @escaping (Int) -> Void) {
        self.index = selectedIndex
        self.onChange = onChange
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = Metrics.tileRadius
        translatesAutoresizingMaskIntoConstraints = false
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 2
        row.edgeInsets = NSEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        for (i, item) in items.enumerated() {
            let (segment, label) = makeSegment(item, i)
            segments.append(segment)
            labels.append(label)
            row.addArrangedSubview(segment)
        }
        apply(animated: false)
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        apply(animated: false)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        apply(animated: false)
    }

    private func makeSegment(_ title: String, _ i: Int) -> (NSView, NSTextField) {
        let label = UI.label(title, font: Typography.sans(12), color: Palette.ink3, align: .center)
        label.usesSingleLineMode = true
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        let click = ClickView()
        click.onClick = { [weak self] in self?.select(i) }
        click.wantsLayer = true
        click.layer?.cornerRadius = 6
        label.translatesAutoresizingMaskIntoConstraints = false
        click.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: click.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: click.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: click.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: click.trailingAnchor, constant: -10)
        ])
        return (click, label)
    }

    private func select(_ i: Int) {
        guard i != index else { return }
        index = i
        apply(animated: true)
        onChange(i)
    }

    private func apply(animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.backgroundColor = cg(Palette.surface2)
        CATransaction.commit()

        for (i, segment) in segments.enumerated() {
            let selected = i == index
            let oldBackground = segment.layer?.presentation()?.backgroundColor ?? segment.layer?.backgroundColor
            let background = cg(selected ? Palette.surface : .clear)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            segment.layer?.backgroundColor = background
            segment.layer?.shadowOpacity = selected ? 0.06 : 0
            segment.layer?.shadowRadius = 1
            segment.layer?.shadowOffset = CGSize(width: 0, height: -0.5)
            segment.layer?.shadowColor = cg(Palette.shadow)
            CATransaction.commit()

            if animated {
                Motion.animate(segment.layer, keyPath: "backgroundColor", from: oldBackground, to: background, duration: Motion.quick, timing: Motion.easeOut)
            }

            labels[i].textColor = selected ? Palette.ink : Palette.ink3
            labels[i].font = Typography.sans(12, selected ? .medium : .regular)
        }
    }
}

