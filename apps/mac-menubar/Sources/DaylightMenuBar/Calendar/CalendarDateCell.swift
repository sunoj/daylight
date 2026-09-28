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
    private var badge: NSTextField?

    // Laid out by frame in `layout()`: a label stack and dot row per cell,
    // times 42 cells, cost ~40ms of Auto Layout on every render.
    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        let showsSubtitle = state?.showsSubtitle ?? true
        return NSSize(width: NSView.noIntrinsicMetric, height: showsSubtitle ? Metrics.cellHeight : Metrics.compactCellHeight)
    }

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
        // Frames are computed once per size; the prewarmed popover lays out
        // before it has a window, so entering one must redo them.
        needsLayout = true
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        needsLayout = true
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
            let badge = CalendarWorkdayBadge.make(color: state.isToday ? Palette.accentInk : Palette.ink2)
            addSubview(badge)
            self.badge = badge
        }
        applyColors(state)
    }

    /// Frame layout reproducing the former constraints: the number (and the
    /// subtitle below it, 1pt apart) centred as one block — 1pt above centre in
    /// a tall cell — kept 2pt inside the edges; dots centred 4pt above the
    /// bottom; the workday badge in the top-trailing corner.
    override func layout() {
        super.layout()
        let showsSubtitle = state?.showsSubtitle ?? true
        let maxWidth = max(bounds.width - 4, 0)
        let daySize = dayLabel.intrinsicContentSize
        var subtitleSize = showsSubtitle ? subtitleLabel.intrinsicContentSize : .zero
        subtitleSize.width = min(subtitleSize.width, maxWidth)
        let stackHeight = daySize.height + (showsSubtitle ? 1 + subtitleSize.height : 0)
        let stackTop = bounds.midY - (showsSubtitle ? 1 : 0) - stackHeight / 2
        // Labels span the usable width with centred text rather than hugging a
        // measured text width, which truncated to "…" when the measurement
        // taken before the popover had a window was a hair short once drawn.
        dayLabel.frame = aligned(NSRect(x: bounds.midX - maxWidth / 2, y: stackTop, width: maxWidth, height: daySize.height))
        if showsSubtitle {
            // Full cell width, as in the Luna cell: holiday names need every
            // point the column has once drawn in the popover.
            subtitleLabel.frame = aligned(NSRect(x: 0, y: stackTop + daySize.height + 1,
                                                 width: bounds.width, height: subtitleSize.height))
        }
        layoutCalendarDots()
        if let badge {
            badge.frame = aligned(CalendarWorkdayBadge.frame(for: badge, in: bounds, flipped: true))
        }
    }

    func aligned(_ rect: NSRect) -> NSRect {
        backingAlignedRect(rect, options: .alignAllEdgesNearest)
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
        dayLabel.stringValue = state.title.primary
        dayLabel.font = Typography.mono(15, .medium)
        dayLabel.alignment = .center
        dayLabel.textColor = numberColor(state)
        addSubview(dayLabel)

        // Compact grids (no subtitle anywhere) omit the second line entirely so
        // the number sits centered in a shorter cell.
        guard state.showsSubtitle else { return }
        subtitleLabel.stringValue = state.title.secondary ?? ""
        subtitleLabel.font = Typography.sans(10, state.title.isSolarTerm ? .semibold : .regular)
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.maximumNumberOfLines = 1
        subtitleLabel.alignment = .center
        subtitleLabel.textColor = subtitleColor(state)
        addSubview(subtitleLabel)
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
