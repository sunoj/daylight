// System-calendar dots for Sol month-grid cells.
// Exports: CalendarDateCell event-dot rendering
// Deps: AppKit, CalendarEvent, Palette, Components

import AppKit

extension CalendarDateCell {
    func configureCalendarDots(_ state: CalendarDateCellState) {
        var colors = Array(state.title.holidayColorIds.prefix(4)).map(Palette.holidayColor)
        var seenCalendars = Set<String>()
        for event in state.events {
            guard colors.count < 4, seenCalendars.insert(event.calendarId).inserted else { continue }
            colors.append(event.color)
        }
        guard !colors.isEmpty else { return }

        calendarDotColors = colors
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 3
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        for color in colors {
            let dot = UI.roundedBox(fill: color, radius: 999)
            dot.alphaValue = state.isToday ? 0.9 : 0.82
            dot.widthAnchor.constraint(equalToConstant: 4).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 4).isActive = true
            row.addArrangedSubview(dot)
            calendarDots.append(dot)
        }
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: centerXAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
}
