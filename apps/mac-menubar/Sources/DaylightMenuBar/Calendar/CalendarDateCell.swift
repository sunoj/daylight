// Day cell for the month grid — mono number, lunar sub, states.
// Exports: CalendarDateCell, CalendarDateCellState
// Deps: AppKit, CalendarEvent, DesignSystem, LocalDate

import AppKit

struct CalendarDateCellState {
    let title: CalendarDayTitle
    let isToday: Bool
    let isSelected: Bool
    let isOutsideMonth: Bool
    let isWeekend: Bool
    /// Whether this grid reserves a subtitle line. Uniform across the grid so
    /// rows align; false collapses cells to compactCellHeight.
    var showsSubtitle: Bool = true
    let events: [CalendarEvent]

    init(
        title: CalendarDayTitle,
        isToday: Bool,
        isSelected: Bool,
        isOutsideMonth: Bool,
        isWeekend: Bool,
        showsSubtitle: Bool = true,
        events: [CalendarEvent] = []
    ) {
        self.title = title
        self.isToday = isToday
        self.isSelected = isSelected
        self.isOutsideMonth = isOutsideMonth
        self.isWeekend = isWeekend
        self.showsSubtitle = showsSubtitle
        self.events = events
    }
}

final class CalendarDateCell: NSControl {
    var localDate: LocalDate?

    private var state: CalendarDateCellState?
    private var allowsHoverFeedback = false
    private var isHovering = false
    private var trackingArea: NSTrackingArea?
    var calendarDots: [NSView] = []
    var calendarDotColors: [NSColor] = []
    private let dayLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")

    init(state: CalendarDateCellState, target: AnyObject?, action: Selector) {
        super.init(frame: .zero)
        self.target = target
        self.action = action
        self.state = state
        configure(state)
    }

    required init?(coder: NSCoder) { nil }

    override func mouseDown(with event: NSEvent) {
        sendAction(action, to: target)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        if let state { applyColors(state) }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let state { applyColors(state) }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        guard allowsHoverFeedback else { return }
        if let trackingArea { removeTrackingArea(trackingArea) }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        guard allowsHoverFeedback, !Motion.isReduced else { return }
        isHovering = true
        animateHoverBackground(to: hoverBackgroundColor)
    }

    override func mouseExited(with event: NSEvent) {
        guard allowsHoverFeedback else { return }
        isHovering = false
        animateHoverBackground(to: cg(.clear))
    }

    private var hoverBackgroundColor: CGColor {
        cg(Palette.surface2.withAlphaComponent(0.55))
    }

    private func animateHoverBackground(to color: CGColor) {
        let from = layer?.presentation()?.backgroundColor ?? layer?.backgroundColor
        Motion.animate(layer, keyPath: "backgroundColor", from: from, to: color, duration: Motion.micro, timing: Motion.easeOut)
        layer?.backgroundColor = color
    }

    private func configure(_ state: CalendarDateCellState) {
        wantsLayer = true
        alphaValue = state.isOutsideMonth ? 0.3 : 1
        toolTip = state.title.holidayTooltip
        layer?.cornerRadius = Metrics.cellRadius
        configureLabels(state)
        configureCalendarDots(state)
        if state.title.isWorkday {
            CalendarWorkdayBadge.add(to: self, color: state.isToday ? Palette.accentInk : Palette.ink2)
        }
        applyColors(state)
        widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        heightAnchor.constraint(equalToConstant: state.showsSubtitle ? Metrics.cellHeight : Metrics.compactCellHeight).isActive = true
    }

    private func applyColors(_ state: CalendarDateCellState) {
        allowsHoverFeedback = !state.isToday && !state.isSelected
        if state.isToday {
            layer?.backgroundColor = cg(Palette.accent)
            layer?.borderWidth = 0
        } else if state.isSelected {
            layer?.backgroundColor = cg(Palette.dateSelection)
            layer?.borderWidth = 1
            layer?.borderColor = cg(Palette.dateSelectionBorder)
        } else {
            layer?.backgroundColor = cg(.clear)
            layer?.borderWidth = 0
        }
        for (index, dot) in calendarDots.enumerated() where index < calendarDotColors.count {
            dot.layer?.backgroundColor = cg(calendarDotColors[index])
        }
    }

    private func configureLabels(_ state: CalendarDateCellState) {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        dayLabel.stringValue = state.title.primary
        dayLabel.font = Typography.mono(15, .medium)
        dayLabel.textColor = numberColor(state)
        stack.addArrangedSubview(dayLabel)

        // Compact grids (no subtitle anywhere) omit the second line entirely so
        // the number sits centered in a shorter cell.
        guard state.showsSubtitle else {
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2),
                stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
                stack.centerXAnchor.constraint(equalTo: centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            return
        }

        subtitleLabel.stringValue = state.title.secondary ?? ""
        subtitleLabel.font = Typography.sans(10, state.title.isSolarTerm ? .semibold : .regular)
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.maximumNumberOfLines = 1
        subtitleLabel.textColor = subtitleColor(state)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -4),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2)
        ])
    }

    private func numberColor(_ state: CalendarDateCellState) -> NSColor {
        if state.isToday { return Palette.accentInk }
        return state.isWeekend ? Palette.ink2 : Palette.ink
    }

    private func subtitleColor(_ state: CalendarDateCellState) -> NSColor {
        if state.isToday { return Palette.accentInk }
        return state.title.isSolarTerm ? Palette.ink : Palette.ink3
    }
}
