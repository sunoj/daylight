// Legal-holiday subscription screen — source radios, iCal URL, subscribe.
// Exports: HolidaySubscriptionPanel
// Deps: AppKit, DaylightStore, DesignSystem, Components, HolidayService

import AppKit

final class SourceButton: RowButton {
    var sourceId: String = ""
}

final class ColorButton: RowButton {
    var subscriptionId: String = ""
}

final class HolidaySubscriptionPanel: NSStackView {
    private let store: DaylightStore
    private let service: HolidayService
    private let onDataChanged: () -> Void
    private let onNeedsRender: () -> Void
    private let onClose: () -> Void
    private let onToast: (String) -> Void
    let nameField = NSTextField()
    let urlField = NSTextField()
    let noteLabel = NSTextField(labelWithString: "")

    init(
        store: DaylightStore,
        onDataChanged: @escaping () -> Void,
        onNeedsRender: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onToast: @escaping (String) -> Void
    ) {
        self.store = store
        self.service = HolidayService(store: store)
        self.onDataChanged = onDataChanged
        self.onNeedsRender = onNeedsRender
        self.onClose = onClose
        self.onToast = onToast
        super.init(frame: .zero)
        orientation = .vertical
        spacing = 8
        alignment = .leading
        edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 10, right: 4)
        render()
    }

    required init?(coder: NSCoder) { nil }

    private func render() {
        let settings = store.settings()
        full(header())
        section(L("来源"))
        full(group(HolidayService.presets.map { source in
            sourceRow(source, subscription: settings.holidaySubscriptions.first { $0.sourceId == source.id && $0.enabled })
        }))
        if let custom = settings.holidaySubscriptions.first(where: { $0.sourceId == "custom" && $0.enabled }) {
            section(L("订阅链接"))
            full(nameRow(custom.name))
            full(urlRow(custom.customURL))
        }
        section(L("自动更新"))
        full(group([updateRow(settings.holidayUpdateWeekly)]))
        full(subscribeButton())
        configureNote(settings)
        full(noteRow())
    }

    private func full(_ view: NSView) {
        addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }

    private func section(_ title: String) {
        let header = UI.sectionHeader(title)
        addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }

    private func header() -> NSView {
        let title = UI.label(L("订阅法定节假日"), font: Typography.sans(18, .semibold), color: Palette.ink)
        let sub = UI.label(L("选择多个来源，自动标注放假与调休"), font: Typography.sans(12), color: Palette.ink3)
        let left = NSStackView(views: [title, sub])
        left.orientation = .vertical
        left.spacing = 3
        left.alignment = .leading
        let row = NSStackView(views: [left, spacer(), closeButton()])
        row.orientation = .horizontal
        row.alignment = .top
        row.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return row
    }

    private func configureNote(_ settings: UserSettings) {
        noteLabel.font = Typography.mono(10)
        noteLabel.textColor = Palette.ink4
        let count = store.holidayDays().count
        noteLabel.stringValue = settings.holidaySubscriptions.contains(where: \.enabled)
            ? "\(L("订阅节假日")) · \(count)"
            : L("未订阅")
    }

    // MARK: Actions

    @objc func close() { onClose() }

    @objc func toggleSource(_ sender: SourceButton) {
        let sourceId = sender.sourceId
        update { settings in
            if let index = settings.holidaySubscriptions.firstIndex(where: { $0.sourceId == sourceId && $0.enabled }) {
                store.removeHolidayDays(for: settings.holidaySubscriptions[index].id)
                settings.holidaySubscriptions.remove(at: index)
            } else {
                settings.holidaySubscriptions.append(HolidaySubscription(
                    id: UUID().uuidString,
                    sourceId: sourceId,
                    customURL: sourceId == "custom" ? urlField.stringValue : "",
                    colorId: "rust",
                    enabled: true,
                    name: sourceId == "custom" ? nameField.stringValue : ""
                ))
            }
        }
    }

    @objc func cycleColor(_ sender: ColorButton) {
        update { settings in
            guard let index = settings.holidaySubscriptions.firstIndex(where: { $0.id == sender.subscriptionId }) else { return }
            let colors = ["rust", "stone", "olive", "amber", "green"]
            let current = colors.firstIndex(of: settings.holidaySubscriptions[index].colorId) ?? 0
            settings.holidaySubscriptions[index].colorId = colors[(current + 1) % colors.count]
        }
    }

    @objc func commitURL() {
        updateCustomURL(urlField.stringValue)
    }

    @objc func pasteURL() {
        if let text = NSPasteboard.general.string(forType: .string) {
            updateCustomURL(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    @objc func subscribe() {
        let settings = store.settings()
        let customURL = urlField.stringValue
        let customName = nameField.stringValue
        let subscriptions = settings.holidaySubscriptions.map { subscription in
            subscription.sourceId == "custom"
                ? HolidaySubscription(id: subscription.id, sourceId: subscription.sourceId, customURL: customURL, colorId: subscription.colorId, enabled: subscription.enabled, name: customName)
                : subscription
        }
        noteLabel.stringValue = L("正在同步…")
        service.subscribe(subscriptions: subscriptions) { [weak self] results in
            guard let self else { return }
            let imported = results.reduce(0) { total, item in
                if case let .success(days) = item.result { return total + days.count }
                return total
            }
            let failures = results.filter {
                if case .failure = $0.result { return true }
                return false
            }
            if failures.isEmpty, !results.isEmpty {
                let resolved = self.resolvedSubscriptions(from: subscriptions, results: results)
                self.onToast("\(L("已订阅")) · \(imported)")
                self.update { $0.holidaySubscriptions = resolved }
                self.noteLabel.stringValue = "\(L("订阅节假日")) · \(imported)"
            } else if !failures.isEmpty {
                if imported > 0 {
                    let resolved = self.resolvedSubscriptions(from: subscriptions, results: results)
                    self.update { $0.holidaySubscriptions = resolved }
                }
                let names = failures.map { L(HolidayService.preset($0.subscription.sourceId)?.name ?? "订阅节假日") }.joined(separator: " · ")
                self.onToast("\(L("同步失败")) · \(names)")
                self.noteLabel.stringValue = "\(L("同步失败")) · \(names)"
            } else {
                self.onToast(L("未订阅"))
                self.noteLabel.stringValue = L("未订阅")
            }
        }
    }

    @objc func commitName() {
        updateCustomName(nameField.stringValue)
    }

    private func updateCustomURL(_ value: String) {
        update { settings in
            guard let index = settings.holidaySubscriptions.firstIndex(where: { $0.sourceId == "custom" && $0.enabled }) else { return }
            settings.holidaySubscriptions[index].customURL = value
        }
    }

    private func updateCustomName(_ value: String) {
        update { settings in
            guard let index = settings.holidaySubscriptions.firstIndex(where: { $0.sourceId == "custom" && $0.enabled }) else { return }
            settings.holidaySubscriptions[index].name = value
        }
    }

    private func resolvedSubscriptions(from subscriptions: [HolidaySubscription], results: [HolidaySubscriptionFetch]) -> [HolidaySubscription] {
        subscriptions.map { subscription in
            results.first { $0.subscription.id == subscription.id }?.subscription ?? subscription
        }
    }

    func update(_ change: (inout UserSettings) -> Void) {
        var settings = store.settings()
        change(&settings)
        store.saveSettings(settings)
        onDataChanged()
        onNeedsRender()
    }
}
