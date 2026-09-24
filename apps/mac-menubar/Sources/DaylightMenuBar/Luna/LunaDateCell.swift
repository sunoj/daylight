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
        translatesAutoresizingMaskIntoConstraints = false
        alphaValue = day.isOutsideMonth ? 0.3 : 1
        toolTip = title.holidayTooltip
        heightAnchor.constraint(equalToConstant: showsSubtitle ? Metrics.lunaCellHeightTall : Metrics.lunaCellHeight).isActive = true
        configure(day: day, title: title, events: events, selectedDate: selectedDate, showsSubtitle: showsSubtitle)
        if title.isWorkday { CalendarWorkdayBadge.add(to: self, color: Palette.ink2) }
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
        let number = UI.label(title.primary, font: Typography.mono(15, .medium), color: numberColor(day: day))
        let subtitle = UI.label(
            title.secondary ?? "",
            font: Typography.sans(Metrics.lunaSubtitleFontSize, title.isSolarTerm ? .semibold : .regular),
            color: subtitleColor(day: day, title: title),
            align: .center
        )
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let labels = NSStackView(views: showsSubtitle ? [number, subtitle] : [number])
        labels.orientation = .vertical
        labels.alignment = .centerX
        labels.spacing = Metrics.lunaLabelStackSpacing
        labels.translatesAutoresizingMaskIntoConstraints = false

        // The dot row's height is reserved in EVERY cell, empty or not. Building
        // the stack only from the views a cell happens to have made its content
        // taller when there were dots, and centring that pushed the number up —
        // so day numbers sat at different heights across one row.
        let dotRow = makeDotRow(title: title, events: events, isToday: day.isToday) ?? emptyDotRow()

        let content = NSStackView(views: [labels, dotRow])
        content.orientation = .vertical
        content.alignment = .centerX
        content.spacing = Metrics.lunaDotRowGap
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        let showsCircle = isToday || isSelected
        if showsCircle {
            let diameter = Metrics.lunaCircleDiameter(showsSubtitle: showsSubtitle)
            let circle: NSView = day.isToday
                ? TodayMoonBackgroundView(date: day.date)
                : UI.roundedBox(fill: Palette.dateSelection, radius: 999, border: Palette.dateSelectionBorder)
            circle.translatesAutoresizingMaskIntoConstraints = false
            addSubview(circle, positioned: .below, relativeTo: content)
            let inset = Metrics.lunaCircleEdgeInset * 2
            let size = circle.widthAnchor.constraint(equalToConstant: diameter)
            size.priority = .defaultHigh
            NSLayoutConstraint.activate([
                circle.centerXAnchor.constraint(equalTo: content.centerXAnchor),
                circle.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                circle.widthAnchor.constraint(equalTo: circle.heightAnchor),
                size,
                circle.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -inset),
                circle.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -inset)
            ])
        } else {
            let diameter = Metrics.lunaCircleDiameter(showsSubtitle: showsSubtitle)
            let circle = UI.roundedBox(fill: Palette.surface2, radius: 999)
            circle.alphaValue = 0
            circle.translatesAutoresizingMaskIntoConstraints = false
            addSubview(circle, positioned: .below, relativeTo: content)
            let inset = Metrics.lunaCircleEdgeInset * 2
            let size = circle.widthAnchor.constraint(equalToConstant: diameter)
            size.priority = .defaultHigh
            NSLayoutConstraint.activate([
                circle.centerXAnchor.constraint(equalTo: content.centerXAnchor),
                circle.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                circle.widthAnchor.constraint(equalTo: circle.heightAnchor),
                size,
                circle.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -inset),
                circle.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -inset)
            ])
            hoverCircle = circle
        }

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Metrics.lunaCircleEdgeInset),
            content.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Metrics.lunaCircleEdgeInset),
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    /// A dot row with no dots: holds the same height so every cell's content
    /// box matches and the numbers line up across the grid.
    private func emptyDotRow() -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: Metrics.lunaDotSize).isActive = true
        spacer.widthAnchor.constraint(equalToConstant: 0).isActive = true
        return spacer
    }

    private func makeDotRow(title: CalendarDayTitle, events: [CalendarEvent], isToday: Bool) -> NSStackView? {
        // Three, not four: the dot row sits below the circle's centre, where the
        // chord is only about 21pt wide — a fourth dot pushes past the curve.
        var colors = Array(title.holidayColorIds.prefix(Metrics.lunaMaxDots)).map(Palette.holidayColor)
        var seen = Set<String>()
        for event in events {
            guard colors.count < Metrics.lunaMaxDots, seen.insert(event.calendarId).inserted else { continue }
            colors.append(event.color)
        }
        guard !colors.isEmpty else { return nil }

        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = Metrics.lunaDotSpacing
        row.translatesAutoresizingMaskIntoConstraints = false
        for color in colors {
            let dot = UI.roundedBox(fill: color, radius: 999)
            dot.alphaValue = isToday ? 1 : 0.82
            dot.widthAnchor.constraint(equalToConstant: Metrics.lunaDotSize).isActive = true
            dot.heightAnchor.constraint(equalToConstant: Metrics.lunaDotSize).isActive = true
            row.addArrangedSubview(dot)
        }
        return row
    }

    private func numberColor(day: CalendarDay) -> NSColor {
        day.isToday ? Palette.todayMoonInk : Palette.ink
    }

    private func subtitleColor(day: CalendarDay, title: CalendarDayTitle) -> NSColor {
        if day.isToday { return Palette.todayMoonInk }
        return title.isSolarTerm ? Palette.ink : Palette.ink3
    }

}
