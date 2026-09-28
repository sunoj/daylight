// Compact calendar day cell with a tinted selection and event dots.
// Exports: LunaDateCell
// Deps: AppKit, CalendarModel, CalendarDayTitle, CalendarEvent, Components, DesignSystem

import AppKit

final class LunaDateCell: NSControl {
    private let date: LocalDate
    private let onSelectDate: (LocalDate) -> Void
    private let isToday: Bool
    private let isSelected: Bool
    private let showsSubtitle: Bool
    private var hoverCircle: NSView?
    private var trackingArea: NSTrackingArea?
    // Laid out by frame in `layout()`. Nested stack views and per-cell
    // constraints made the 42-cell grid cost ~40ms of Auto Layout per render.
    private var number = NSTextField()
    private var subtitle: NSTextField?
    private var dots: [NSView] = []
    private var circle: NSView?
    private var badge: NSTextField?

    init(
        day: CalendarDay,
        title: CalendarDayTitle,
        events: [CalendarEvent],
        selectedDate: LocalDate,
        showsSubtitle: Bool,
        onSelectDate: @escaping (LocalDate) -> Void
    ) {
        self.date = day.date
        self.onSelectDate = onSelectDate
        self.isToday = day.isToday
        self.isSelected = day.date == selectedDate
        self.showsSubtitle = showsSubtitle
        super.init(frame: .zero)
        alphaValue = day.isOutsideMonth ? 0.3 : 1
        toolTip = title.holidayTooltip
        configure(day: day, title: title, events: events, selectedDate: selectedDate, showsSubtitle: showsSubtitle)
        if title.isWorkday {
            let badge = CalendarWorkdayBadge.make(color: Palette.ink2)
            addSubview(badge)
            self.badge = badge
        }
    }

    required init?(coder: NSCoder) { nil }

    override func mouseDown(with event: NSEvent) {
        onSelectDate(date)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        guard hoverCircle != nil else { return }
        if let trackingArea { removeTrackingArea(trackingArea) }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        guard hoverCircle != nil, !Motion.isReduced else { return }
        animateHover(alpha: 0.55)
    }

    override func mouseExited(with event: NSEvent) {
        guard hoverCircle != nil else { return }
        animateHover(alpha: 0)
    }

    private func animateHover(alpha: CGFloat) {
        guard let hoverCircle else { return }
        Motion.run(duration: Motion.micro, timing: Motion.easeOut) {
            hoverCircle.animator().alphaValue = alpha
        }
    }

    private func configure(
        day: CalendarDay,
        title: CalendarDayTitle,
        events: [CalendarEvent],
        selectedDate: LocalDate,
        showsSubtitle: Bool
    ) {
        let showsCircle = isToday || isSelected
        let circle: NSView
        if showsCircle {
            circle = day.isToday
                ? TodayMoonBackgroundView(date: day.date)
                : UI.roundedBox(fill: Palette.dateSelection, radius: 999, border: Palette.dateSelectionBorder)
        } else {
            circle = UI.roundedBox(fill: Palette.surface2, radius: 999)
            circle.alphaValue = 0
            hoverCircle = circle
        }
        self.circle = circle

        number = UI.label(title.primary, font: Typography.mono(15, .medium), color: numberColor(day: day), align: .center)
        if showsSubtitle {
            let subtitle = UI.label(
                title.secondary ?? "",
                font: Typography.sans(Metrics.lunaSubtitleFontSize, title.isSolarTerm ? .semibold : .regular),
                color: subtitleColor(day: day, title: title),
                align: .center
            )
            subtitle.lineBreakMode = .byTruncatingTail
            self.subtitle = subtitle
        }
        dots = makeDots(title: title, events: events, isToday: day.isToday)

        for view in [circle, number] + [subtitle].compactMap { $0 } + dots {
            view.translatesAutoresizingMaskIntoConstraints = true
            addSubview(view)
        }
    }

    // Frames are computed once per size, so a move into a window (the
    // prewarmed popover is laid out before it has one) must redo them.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsLayout = true
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        needsLayout = true
    }

    /// Frame layout reproducing the former stacks: a vertical label stack
    /// (number, optional subtitle) above a dot row whose height is reserved in
    /// EVERY cell, so numbers line up across a row whether or not a cell has
    /// dots; the whole content centred in the cell; the circle centred on the
    /// content and capped by the cell's edge insets.
    override func layout() {
        super.layout()
        let inset = Metrics.lunaCircleEdgeInset
        let available = max(bounds.width - 2 * inset, 0)

        let numberSize = number.intrinsicContentSize
        var subtitleSize = subtitle?.intrinsicContentSize ?? .zero
        subtitleSize.width = min(subtitleSize.width, available)
        let dotCount = CGFloat(dots.count)
        let dotRowWidth = dotCount > 0 ? dotCount * Metrics.lunaDotSize + (dotCount - 1) * Metrics.lunaDotSpacing : 0

        let labelsHeight = numberSize.height + (subtitle == nil ? 0 : Metrics.lunaLabelStackSpacing + subtitleSize.height)
        let contentHeight = labelsHeight + Metrics.lunaDotRowGap + Metrics.lunaDotSize
        let contentWidth = min(max(numberSize.width, subtitleSize.width, dotRowWidth), available)
        let content = NSRect(x: (bounds.width - contentWidth) / 2, y: (bounds.height - contentHeight) / 2,
                             width: contentWidth, height: contentHeight)

        // Labels span the whole usable width with their text centred, rather
        // than hugging a measured text width: a frame exactly as wide as the
        // text measured before the popover had a window truncated every date
        // to "…" once drawn in it.
        number.frame = aligned(NSRect(x: content.midX - available / 2, y: content.maxY - numberSize.height,
                                      width: available, height: numberSize.height))
        // The subtitle takes the cell's full width: the circle's edge inset
        // has nothing to do with text, and a three-character holiday name
        // such as 国庆节 needs ~33.5pt once drawn in the popover, more than
        // the inset left in a 37pt column.
        if let subtitle {
            subtitle.frame = aligned(NSRect(x: 0,
                                            y: content.maxY - numberSize.height - Metrics.lunaLabelStackSpacing - subtitleSize.height,
                                            width: bounds.width, height: subtitleSize.height))
        }
        var dotX = content.midX - dotRowWidth / 2
        for dot in dots {
            dot.frame = aligned(NSRect(x: dotX, y: content.minY, width: Metrics.lunaDotSize, height: Metrics.lunaDotSize))
            dotX += Metrics.lunaDotSize + Metrics.lunaDotSpacing
        }
        let diameter = min(Metrics.lunaCircleDiameter(showsSubtitle: showsSubtitle), available, bounds.height - 2 * inset)
        circle?.frame = aligned(NSRect(x: content.midX - diameter / 2, y: content.midY - diameter / 2,
                                       width: diameter, height: diameter))
        if let badge {
            badge.frame = aligned(CalendarWorkdayBadge.frame(for: badge, in: bounds, flipped: false))
        }
    }

    private func aligned(_ rect: NSRect) -> NSRect {
        backingAlignedRect(rect, options: .alignAllEdgesNearest)
    }

    private func makeDots(title: CalendarDayTitle, events: [CalendarEvent], isToday: Bool) -> [NSView] {
        // Three, not four: the dot row sits below the circle's centre, where the
        // chord is only about 21pt wide — a fourth dot pushes past the curve.
        var colors = Array(title.holidayColorIds.prefix(Metrics.lunaMaxDots)).map(Palette.holidayColor)
        var seen = Set<String>()
        for event in events {
            guard colors.count < Metrics.lunaMaxDots, seen.insert(event.calendarId).inserted else { continue }
            colors.append(event.color)
        }
        return colors.map { color in
            let dot = UI.roundedBox(fill: color, radius: 999)
            dot.alphaValue = isToday ? 1 : 0.82
            return dot
        }
    }

    private func numberColor(day: CalendarDay) -> NSColor {
        day.isToday ? Palette.todayMoonInk : Palette.ink
    }

    private func subtitleColor(day: CalendarDay, title: CalendarDayTitle) -> NSColor {
        if day.isToday { return Palette.todayMoonInk }
        return title.isSolarTerm ? Palette.ink : Palette.ink3
    }

}
