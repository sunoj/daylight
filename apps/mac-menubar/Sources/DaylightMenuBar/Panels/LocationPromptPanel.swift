// Pre-prompt shown before the system location dialog for the 3D moon.
// Exports: LocationPromptPanel
// Deps: AppKit, DesignSystem, Components, MoonDiscView

import AppKit

final class LocationPromptPanel: NSStackView {
    private let onAllow: () -> Void
    private let onSkip: () -> Void

    init(onAllow: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.onAllow = onAllow
        self.onSkip = onSkip
        super.init(frame: .zero)
        orientation = .vertical
        spacing = 16
        alignment = .centerX
        edgeInsets = NSEdgeInsets(top: 10, left: 20, bottom: 16, right: 20)
        build()
    }

    required init?(coder: NSCoder) { nil }

    private func build() {
        addArrangedSubview(handle())
        addArrangedSubview(moonGraphic())
        let title = UI.label(L("允许「昼间」使用你的位置？"), font: Typography.sans(17, .semibold), color: Palette.ink, align: .center)
        addArrangedSubview(title)
        let body = UI.label(
            L("3D 月相会根据你的经纬度计算月亮的方位角、高度角与天平动，呈现今夜真实的朝向。位置仅在本地使用，不会上传或分享。"),
            font: Typography.sans(13), color: Palette.ink2, align: .center
        )
        body.lineBreakMode = .byWordWrapping
        body.maximumNumberOfLines = 0
        body.preferredMaxLayoutWidth = Metrics.popoverWidth - 92
        addArrangedSubview(body)
        addArrangedSubview(chips())
        // Add each pill BEFORE pinning its width to self: activating a constraint
        // between two views with no common ancestor yet throws, which left this
        // whole screen blank.
        for pill in [pillButton(L("允许使用定位"), filled: true, action: #selector(allow)),
                     pillButton(L("暂不开启"), filled: false, action: #selector(skip))] {
            addArrangedSubview(pill)
            pill.widthAnchor.constraint(equalTo: widthAnchor, constant: -40).isActive = true
        }
        widthConstraint(title)
        widthConstraint(body)
    }

    private func widthConstraint(_ view: NSView) {
        view.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40).isActive = true
    }

    private func handle() -> NSView {
        let bar = UI.roundedBox(fill: Palette.line2, radius: 2.5)
        bar.widthAnchor.constraint(equalToConstant: 36).isActive = true
        bar.heightAnchor.constraint(equalToConstant: 5).isActive = true
        return bar
    }

    private func moonGraphic() -> NSView {
        let container = NSView()
        container.widthAnchor.constraint(equalToConstant: 96).isActive = true
        container.heightAnchor.constraint(equalToConstant: 96).isActive = true
        let disc = MoonDiscView(frame: .zero)
        disc.fraction = 0.62
        disc.waxing = true
        disc.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(disc)
        let badge = UI.roundedBox(fill: Palette.ink, radius: 16)
        let pin = NSImageView(image: NSImage(systemSymbolName: "location.fill", accessibilityDescription: nil) ?? NSImage())
        pin.contentTintColor = Palette.accentInk
        pin.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(pin)
        badge.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(badge)
        NSLayoutConstraint.activate([
            disc.topAnchor.constraint(equalTo: container.topAnchor),
            disc.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            disc.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            disc.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 32),
            badge.heightAnchor.constraint(equalToConstant: 32),
            badge.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 2),
            badge.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 2),
            pin.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        return container
    }

    private func chips() -> NSView {
        let row = NSStackView(views: [chip(L("仅本地计算")), chip(L("可随时关闭"))])
        row.orientation = .horizontal
        row.spacing = 8
        return row
    }

    private func chip(_ text: String) -> NSView {
        let box = UI.roundedBox(fill: .clear, radius: 999, border: Palette.line)
        let label = UI.label(text, font: Typography.mono(10.5), color: Palette.ink3)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: box.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -10)
        ])
        return box
    }

    private func pillButton(_ title: String, filled: Bool, action: Selector) -> NSView {
        if filled {
            return UI.filledButton(title, target: self, action: action, height: 44, radius: 999)
        }
        let button = RowButton(target: self, action: action)
        let box = UI.roundedBox(fill: .clear, radius: 999, border: Palette.line)
        let label = UI.label(title, font: Typography.sans(15, .medium), color: Palette.ink, align: .center)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
        button.addContentView(box)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    @objc private func allow() { onAllow() }
    @objc private func skip() { onSkip() }
}
