// Quick diary timeline and input row for the Sol calendar screen.
// Exports: PopoverViewController quick diary builders, QuickDiaryInputAppearance
// Deps: AppKit, DesignSystem, Components, DiaryThoughtTimelineView

import AppKit

enum QuickDiaryInputAppearance {
    case sol
    case lunaPanel
}

extension PopoverViewController {
    func quickDiarySection() -> NSView {
        let thoughts = store.thoughts(for: selectedDate)
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 10
        stack.alignment = .leading
        if !thoughts.isEmpty {
            let timeline = DiaryThoughtTimelineView()
            timeline.translatesAutoresizingMaskIntoConstraints = false
            timeline.onDelete = { [weak self] id in
                guard let self else { return }
                self.store.deleteThought(id: id)
                self.onDataChanged()
                self.showToast(L("已删除"))
                self.render()
            }
            timeline.onToggle = { [weak self] id in
                guard let self else { return }
                self.store.toggleThought(id: id)
                self.onDataChanged()
                self.render()
            }
            timeline.render(thoughts: thoughts)
            stack.addArrangedSubview(timeline)
            timeline.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        stack.addArrangedSubview(quickDiaryInputRow(appearance: .sol))
        return pad(stack, top: 12, left: 16, bottom: 14, right: 16)
    }

    func quickDiaryInputRow(appearance: QuickDiaryInputAppearance = .sol) -> NSView {
        quickDiaryField.stringValue = ""
        let placeholder = Loc.quickDiaryPlaceholder(for: selectedDate, today: calendarModel.today())
        quickDiaryField.font = Typography.sans(12.5)
        quickDiaryField.isBordered = false
        quickDiaryField.drawsBackground = false
        quickDiaryField.focusRingType = .none
        quickDiaryField.target = self
        quickDiaryField.action = #selector(saveQuickDiary)
        quickDiaryField.delegate = self
        let fieldBox: NSView
        switch appearance {
        case .sol:
            // Cleared first: assigning a nil attributed placeholder after the
            // plain one wipes it out, leaving Sol's field with no prompt at all.
            quickDiaryField.placeholderAttributedString = nil
            quickDiaryField.placeholderString = placeholder
            quickDiaryField.textColor = Palette.ink
            fieldBox = UI.roundedBox(fill: Palette.surface2, radius: Metrics.tileRadius, border: Palette.line)
        case .lunaPanel:
            quickDiaryField.placeholderString = ""
            quickDiaryField.placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: Palette.eventInk3,
                .font: Typography.sans(12.5)
            ])
            quickDiaryField.textColor = Palette.eventInk
            // The footer tone, not the panel's own: an input filled with the
            // surface it sits on reads as a border floating in space.
            fieldBox = UI.roundedBox(fill: Palette.eventFooter, radius: Metrics.tileRadius, border: Palette.eventLine)
        }
        quickDiaryField.translatesAutoresizingMaskIntoConstraints = false
        fieldBox.addSubview(quickDiaryField)
        NSLayoutConstraint.activate([
            fieldBox.heightAnchor.constraint(equalToConstant: 34),
            quickDiaryField.leadingAnchor.constraint(equalTo: fieldBox.leadingAnchor, constant: 12),
            quickDiaryField.trailingAnchor.constraint(equalTo: fieldBox.trailingAnchor, constant: -12),
            quickDiaryField.centerYAnchor.constraint(equalTo: fieldBox.centerYAnchor)
        ])
        let save = UI.filledButton(
            L("保存"), target: self, action: #selector(saveQuickDiary), height: 34,
            fill: appearance == .sol ? Palette.ink : Palette.eventInk,
            titleColor: appearance == .sol ? Palette.accentInk : Palette.eventPanel
        )
        let saveButton = save as? RowButton
        let saveWidth = (L("保存") as NSString).size(withAttributes: [.font: Typography.sans(12.5, .medium)]).width
        save.widthAnchor.constraint(greaterThanOrEqualToConstant: ceil(saveWidth) + 30).isActive = true
        saveButton?.isEnabled = !quickDiaryField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        quickDiarySaveButton = saveButton
        let row = NSStackView(views: [fieldBox, save])
        row.orientation = .horizontal
        row.spacing = 8
        row.distribution = .fill
        fieldBox.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return row
    }
}
