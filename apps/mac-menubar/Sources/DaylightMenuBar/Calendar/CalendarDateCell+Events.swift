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
        for color in colors {
            let dot = UI.roundedBox(fill: color, radius: 999)
            dot.alphaValue = state.isToday ? 0.9 : 0.82
            dot.translatesAutoresizingMaskIntoConstraints = true
            addSubview(dot)
            calendarDots.append(dot)
        }
    }

    /// Dots centred horizontally, their bottom 4pt above the cell's.
    func layoutCalendarDots() {
        let size: CGFloat = 4, spacing: CGFloat = 3
        let count = CGFloat(calendarDots.count)
        var x = bounds.midX - (count * size + max(count - 1, 0) * spacing) / 2
        for dot in calendarDots {
            dot.frame = aligned(NSRect(x: x, y: bounds.maxY - 4 - size, width: size, height: size))
            x += size + spacing
        }
    }
}
