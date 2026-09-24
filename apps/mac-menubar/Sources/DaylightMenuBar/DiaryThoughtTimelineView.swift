// Scrollable diary thought timeline rows for quick diary and detail screens.
// Exports: DiaryThoughtTimelineStyle, DiaryThoughtTimelineView, DiaryThoughtDeleteButton, DiaryThoughtToggleButton
// Deps: AppKit, DesignSystem, Components

import AppKit

struct DiaryThoughtTimelineStyle {
    let timeColor: NSColor
    let textColor: NSColor
    let doneTextColor: NSColor
    let deleteGlyphColor: NSColor
    let armedDeleteColor: NSColor
    let uncheckedBoxColor: NSColor
    let checkedBoxColor: NSColor
    let maxHeight: CGFloat

    static let light = DiaryThoughtTimelineStyle(
        timeColor: Palette.ink4,
        textColor: Palette.ink2,
        doneTextColor: Palette.ink4,
        deleteGlyphColor: Palette.ink4,
        armedDeleteColor: Palette.rust,
        uncheckedBoxColor: Palette.ink3,
        checkedBoxColor: Palette.ink4,
        maxHeight: 160
    )

    static let dark = DiaryThoughtTimelineStyle(
        timeColor: Palette.eventInk2,
        textColor: Palette.eventInk,
        doneTextColor: Palette.eventInk3,
        deleteGlyphColor: Palette.eventInk3,
        armedDeleteColor: Palette.rust,
        uncheckedBoxColor: Palette.eventInk3,
        checkedBoxColor: Palette.eventInk3,
        maxHeight: 132
    )
}

final class DiaryThoughtDeleteButton: RowButton {
    var thoughtId: String?
    private let glyph = NSImageView()
    private(set) var isArmed = false
    var style: DiaryThoughtTimelineStyle = .light {
        didSet { updateGlyph() }
    }

    override init(target: AnyObject?, action: Selector) {
        super.init(target: target, action: action)
        addContentView(glyph)
        updateGlyph()
    }

    required init?(coder: NSCoder) { nil }

    func setArmed(_ armed: Bool) {
        guard isArmed != armed else { return }
        isArmed = armed
        updateGlyph()
    }

    private func updateGlyph() {
        let symbol = isArmed ? "checkmark" : "xmark"
        let description = isArmed ? L("确认删除") : L("删除")
        glyph.image = NSImage(systemSymbolName: symbol, accessibilityDescription: description) ?? NSImage()
        glyph.contentTintColor = isArmed ? style.armedDeleteColor : style.deleteGlyphColor
    }
}

final class DiaryThoughtToggleButton: RowButton {
    var thoughtId: String?
}

final class DiaryThoughtTimelineView: NSView {
    var onDelete: ((String) -> Void)?
    var onToggle: ((String) -> Void)?
    private let style: DiaryThoughtTimelineStyle
    private var armedThoughtId: String?
    private weak var armedDeleteButton: DiaryThoughtDeleteButton?
    private weak var scrollView: NSScrollView?

    init(style: DiaryThoughtTimelineStyle = .light) {
        self.style = style
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    func render(thoughts: [DiaryThought]) {
        armedThoughtId = nil
        armedDeleteButton = nil
        subviews.forEach { $0.removeFromSuperview() }
        guard !thoughts.isEmpty else { return }
        let document = NSView()
        document.translatesAutoresizingMaskIntoConstraints = false
        let rows = NSStackView()
        rows.orientation = .vertical
        rows.spacing = 8
        rows.alignment = .leading
        rows.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: document.topAnchor),
            rows.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: document.bottomAnchor),
            rows.widthAnchor.constraint(equalTo: document.widthAnchor)
        ])
        // Each row must span the stack, or a .leading vertical stack leaves it at
        // its intrinsic width and the row's trailing spacer has nothing to fill —
        // which pinned the delete control to the end of the text instead of the
        // end of the row.
        DiaryThoughtCodec.sortedOldestFirst(thoughts).forEach { thought in
            let row = thoughtRow(thought)
            rows.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: rows.widthAnchor).isActive = true
        }
        let scroll = NSScrollView()
        scroll.documentView = document
        // Without this the document sizes to its own content, so every row —
        // and the text inside it — collapses to intrinsic width instead of
        // filling the panel.
        document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor).isActive = true
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .overlay
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        let hug = scroll.heightAnchor.constraint(equalTo: document.heightAnchor)
        hug.priority = .defaultHigh
        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            hug,
            scroll.heightAnchor.constraint(lessThanOrEqualToConstant: style.maxHeight)
        ])
        scrollView = scroll
        scroll.layoutSubtreeIfNeeded()
    }

    /// Explicit constraints rather than stack priorities: the time hugs the
    /// leading edge, the delete control the trailing edge, and the text takes
    /// whatever is between. Tuning hugging on a nested stack collapsed the text
    /// to 4pt instead.
    private func thoughtRow(_ thought: DiaryThought) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let time = UI.label(DiaryThoughtTimeLabel.text(for: thought.createdAt), font: Typography.mono(10.5), color: style.timeColor)
        let text = UI.label(thought.content, font: Typography.sans(12.5), color: style.textColor)
        if thought.done == true {
            text.textColor = style.doneTextColor
            text.attributedStringValue = NSAttributedString(string: thought.content, attributes: [
                .font: Typography.sans(12.5),
                .foregroundColor: style.doneTextColor,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: style.doneTextColor
            ])
        }
        text.lineBreakMode = .byWordWrapping
        text.maximumNumberOfLines = 0
        let toggle: DiaryThoughtToggleButton?
        if let done = thought.done {
            let button = DiaryThoughtToggleButton(target: self, action: #selector(toggleThought(_:)))
            button.thoughtId = thought.id
            let symbol = done ? "checkmark.square.fill" : "square"
            let glyph = NSImageView(image: NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage())
            glyph.contentTintColor = done ? style.checkedBoxColor : style.uncheckedBoxColor
            button.addContentView(glyph)
            toggle = button
        } else {
            toggle = nil
        }
        let remove = DiaryThoughtDeleteButton(target: self, action: #selector(deleteThought(_:)))
        remove.thoughtId = thought.id
        remove.style = style

        for view in [time, text, remove] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(view)
        }
        toggle?.translatesAutoresizingMaskIntoConstraints = false
        if let toggle { row.addSubview(toggle) }
        let textLeading: NSLayoutConstraint
        if let toggle {
            textLeading = text.leadingAnchor.constraint(equalTo: toggle.trailingAnchor, constant: 6)
        } else {
            textLeading = text.leadingAnchor.constraint(equalTo: time.trailingAnchor, constant: 8)
        }
        var constraints = [
            time.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            time.firstBaselineAnchor.constraint(equalTo: text.firstBaselineAnchor),
            textLeading,
            text.topAnchor.constraint(equalTo: row.topAnchor),
            text.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            text.trailingAnchor.constraint(lessThanOrEqualTo: remove.leadingAnchor, constant: -8),
            remove.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            remove.topAnchor.constraint(equalTo: row.topAnchor),
            remove.widthAnchor.constraint(equalToConstant: 20),
            remove.heightAnchor.constraint(equalToConstant: 20)
        ]
        if let toggle {
            constraints += [
                toggle.leadingAnchor.constraint(equalTo: time.trailingAnchor, constant: 8),
                toggle.topAnchor.constraint(equalTo: row.topAnchor),
                toggle.widthAnchor.constraint(equalToConstant: 18),
                toggle.heightAnchor.constraint(equalToConstant: 20)
            ]
        }
        NSLayoutConstraint.activate(constraints)
        return row
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    @objc private func deleteThought(_ sender: DiaryThoughtDeleteButton) {
        guard let id = sender.thoughtId else { return }
        if armedThoughtId == id {
            armedThoughtId = nil
            armedDeleteButton = nil
            sender.setArmed(false)
            onDelete?(id)
            return
        }
        armedDeleteButton?.setArmed(false)
        armedThoughtId = id
        armedDeleteButton = sender
        sender.setArmed(true)
    }

    @objc private func toggleThought(_ sender: DiaryThoughtToggleButton) {
        guard let id = sender.thoughtId else { return }
        onToggle?(id)
    }
}

enum DiaryThoughtTimeLabel {
    static func text(for iso: String) -> String {
        guard let saved = ISO8601DateFormatter().date(from: iso) ?? fractionalFormatter.date(from: iso) else { return "" }
        if Date().timeIntervalSince(saved) < 60 { return L("刚刚") }
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar(identifier: .gregorian).isDateInToday(saved) ? "HH:mm" : "yyyy-MM-dd"
        return formatter.string(from: saved)
    }

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
