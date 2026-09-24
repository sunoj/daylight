// Header controls for the compact month grid.
// Exports: LunaHeaderView
// Deps: AppKit, Components, DesignSystem, Localization

import AppKit

final class LunaHeaderView: NSStackView {
    private let onPrevious: () -> Void
    private let onNext: () -> Void
    private let onJumpToday: () -> Void
    private let onZoomOut: () -> Void

    init(
        title: String,
        lunarSubtitle: String?,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onJumpToday: @escaping () -> Void,
        onZoomOut: @escaping () -> Void
    ) {
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onJumpToday = onJumpToday
        self.onZoomOut = onZoomOut
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 8
        alignment = .centerY
        edgeInsets = NSEdgeInsets(top: 16, left: 18, bottom: 10, right: 16)
        addArrangedSubview(titleButton(title: title, lunarSubtitle: lunarSubtitle))
        addArrangedSubview(spacer())
        addArrangedSubview(navigationPill())
    }

    required init?(coder: NSCoder) { nil }

    /// Tapping the title zooms out to the month, then year, then decade picker,
    /// as Sol's title does. Jumping to today moved into the navigation pill when
    /// this took over the title's tap.
    private func titleButton(title: String, lunarSubtitle: String?) -> NSView {
        let button = RowButton(target: self, action: #selector(zoomOut))
        let title = UI.label(title, font: Typography.sans(21, .semibold), color: Palette.ink)
        title.setContentCompressionResistancePriority(.required, for: .horizontal)
        // The lunar year and month sit under the title only when the grid is
        // already showing lunar dates, matching Sol's header.
        guard let lunarSubtitle, !lunarSubtitle.isEmpty else {
            button.addContentView(title)
            return button
        }
        let subtitle = UI.label(lunarSubtitle, font: Typography.sans(11), color: Palette.ink3)
        let column = NSStackView(views: [title, subtitle])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 2
        button.addContentView(column)
        return button
    }

    private func navigationPill() -> NSView {
        let pill = UI.roundedBox(fill: Palette.surface2, radius: 999)
        pill.widthAnchor.constraint(equalToConstant: 102).isActive = true
        pill.heightAnchor.constraint(equalToConstant: 30).isActive = true
        let row = NSStackView(views: [
            arrow("chevron.left", action: #selector(previous)),
            arrow("calendar", action: #selector(jumpToday)),
            arrow("chevron.right", action: #selector(next))
        ])
        row.orientation = .horizontal
        row.spacing = 0
        row.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: pill.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: pill.trailingAnchor),
            row.topAnchor.constraint(equalTo: pill.topAnchor),
            row.bottomAnchor.constraint(equalTo: pill.bottomAnchor)
        ])
        return pill
    }

    private func arrow(_ symbol: String, action: Selector) -> NSView {
        let button = RowButton(target: self, action: action)
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.addContentView(glyph(symbol))
        return button
    }

    private func glyph(_ symbol: String) -> NSImageView {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
        let view = NSImageView(image: image ?? NSImage())
        view.contentTintColor = Palette.ink2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    @objc private func previous() { onPrevious() }
    @objc private func next() { onNext() }
    @objc private func jumpToday() { onJumpToday() }
    @objc private func zoomOut() { onZoomOut() }
}
