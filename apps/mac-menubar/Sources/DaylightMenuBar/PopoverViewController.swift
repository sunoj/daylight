// Popover shell: header, month grid, moon row, quick diary, screen routing.
// Exports: PopoverViewController
// Deps: AppKit, Calendar views, settings panels, moon panel

import AppKit
import QuartzCore

final class PopoverRootView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    var fillColor: NSColor = .clear { didSet { needsDisplay = true } }
    override var acceptsFirstResponder: Bool { true }
    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = cg(fillColor)
        layer?.isOpaque = fillColor.alphaComponent >= 1
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if onKeyDown?(event) == true { return }
        super.keyDown(with: event)
    }
}

enum PopoverScreen: Equatable {
    case calendar
    case luna
    case settings
    case systemCalendar
    case statusEditor
    case locationPrompt
    case moon
    case holidays
}

final class PopoverViewController: NSViewController {
    let store: DaylightStore
    let calendarModel: CalendarModel
    let lunarCalendar = LunarCalendar()
    let onDataChanged: () -> Void
    var selectedDate: LocalDate
    var visibleMonth: LocalDate
    var viewMode: CalendarViewMode = .month
    var screen: PopoverScreen = .calendar
    var moonWantsLocation = true
    var moonDisplayDate: LocalDate
    var lunaDiaryComposing = false
    let rootStack = NSStackView()
    let quickDiaryField = NSTextField()
    weak var quickDiarySaveButton: RowButton?
    private let toastLabel = NSTextField(labelWithString: "")
    private lazy var toastBox: NSView = makeToast()
    private var toastTimer: Timer?
    private var popoverWidthConstraint: NSLayoutConstraint!
    private var lastRenderState: PopoverRenderState?
    private var transitionOverlay: NSImageView?
    private lazy var renderCoalescer = RenderCoalescer { [weak self] in
        self?.renderOnce()
    }

    var homeScreen: PopoverScreen {
        store.settings().isLunaUI ? .luna : .calendar
    }

    init(store: DaylightStore, calendarModel: CalendarModel, onDataChanged: @escaping () -> Void) {
        self.store = store
        self.calendarModel = calendarModel
        self.onDataChanged = onDataChanged
        self.selectedDate = calendarModel.today()
        self.visibleMonth = LocalDate(year: selectedDate.year, month: selectedDate.month, day: 1)
        self.moonDisplayDate = selectedDate
        super.init(nibName: nil, bundle: nil)
        screen = homeScreen
        SystemCalendarService.shared.onChange = { [weak self] in
            guard let self, self.isViewLoaded else { return }
            self.render()
        }
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() {
        let width = screen == .luna ? Metrics.lunaPopoverWidth : Metrics.popoverWidth
        let rootView = PopoverRootView(frame: NSRect(x: 0, y: 0, width: width, height: 560))
        rootView.onKeyDown = { [weak self] event in self?.handleKeyDown(event) ?? false }
        rootView.wantsLayer = true
        view = rootView
        configureRootStack()
        render()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        applyAppearance()
        view.window?.makeFirstResponder(view)
    }

    private func configureRootStack() {
        (view as? PopoverRootView)?.fillColor = Palette.popoverBackground
        rootStack.orientation = .vertical
        rootStack.spacing = 0
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: view.topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        popoverWidthConstraint = view.widthAnchor.constraint(equalToConstant: currentPopoverWidth)
        popoverWidthConstraint.isActive = true
    }

    func render() {
        renderCoalescer.request()
    }

    private func renderOnce() {
        let newState = PopoverRenderState(
            screen: screen,
            viewMode: viewMode,
            visibleMonth: visibleMonth,
            selectedDate: selectedDate
        )
        let transition = ScreenTransition.resolve(from: lastRenderState, to: newState)
        removeTransitionOverlay()

        var snapshot: NSImageView?
        if transition != .none, !Motion.isReduced, lastRenderState != nil {
            snapshot = captureTransitionSnapshot()
            if let snapshot {
                insertTransitionOverlay(snapshot)
                transitionOverlay = snapshot
            }
        }

        popoverWidthConstraint?.constant = currentPopoverWidth
        rootStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        Loc.language = AppLanguage(rawValue: store.settings().language) ?? .zh
        applyAppearance()
        (view as? PopoverRootView)?.fillColor = currentRootFill
        view.needsDisplay = true
        let screenView: NSView
        switch screen {
        case .calendar: screenView = calendarScreen()
        case .luna: screenView = lunaScreen()
        case .settings: screenView = settingsScreen()
        case .systemCalendar: screenView = systemCalendarScreen()
        case .statusEditor: screenView = statusEditorScreen()
        case .locationPrompt: screenView = locationPromptScreen()
        case .moon: screenView = moonScreen()
        case .holidays: screenView = holidaysScreen()
        }
        rootStack.addArrangedSubview(screenView)
        screenView.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true
        sizeToFit(screenView)

        if screen == .luna, lunaDiaryComposing {
            // The field is rebuilt by this very render, so it can only take
            // focus once the new view tree is in the window.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.view.window?.makeFirstResponder(self.quickDiaryField)
            }
        }

        if let snapshot, transition != .none, !Motion.isReduced {
            playTransition(transition, overlay: snapshot)
        }

        lastRenderState = newState
    }

    private func captureTransitionSnapshot() -> NSImageView? {
        guard !rootStack.arrangedSubviews.isEmpty else { return nil }
        view.layoutSubtreeIfNeeded()
        let frame = rootStack.frame
        guard frame.width > 0, frame.height > 0 else { return nil }
        guard let rep = rootStack.bitmapImageRepForCachingDisplay(in: frame) else { return nil }
        rootStack.cacheDisplay(in: frame, to: rep)
        let image = NSImage(size: frame.size)
        image.addRepresentation(rep)
        let imageView = NSImageView(frame: frame)
        imageView.image = image
        imageView.imageScaling = .scaleAxesIndependently
        imageView.translatesAutoresizingMaskIntoConstraints = true
        // Content is laid out from the top, but an unmasked subview keeps its
        // frame relative to the bottom-left. Months with five vs six week rows
        // resize the popover mid-transition, which slid the snapshot against the
        // new content; a flexible bottom margin keeps its top edge put.
        imageView.autoresizingMask = [.minYMargin]
        return imageView
    }

    private func insertTransitionOverlay(_ overlay: NSImageView) {
        if toastBox.superview != nil {
            view.addSubview(overlay, positioned: .below, relativeTo: toastBox)
        } else {
            view.addSubview(overlay)
        }
    }

    private func removeTransitionOverlay() {
        transitionOverlay?.layer?.removeAllAnimations()
        transitionOverlay?.removeFromSuperview()
        transitionOverlay = nil
        rootStack.layer?.removeAllAnimations()
        rootStack.layer?.opacity = 1
        rootStack.layer?.transform = CATransform3DIdentity
    }

    private func finishTransition() {
        transitionOverlay?.removeFromSuperview()
        transitionOverlay = nil
        rootStack.layer?.opacity = 1
        rootStack.layer?.transform = CATransform3DIdentity
    }

    private func playTransition(_ transition: ScreenTransition, overlay: NSImageView) {
        rootStack.wantsLayer = true
        overlay.wantsLayer = true
        guard let overlayLayer = overlay.layer, let rootLayer = rootStack.layer else {
            finishTransition()
            return
        }

        // Model values are set to where each layer ENDS, and the animations below
        // only supply the `from` side. An animation drives the presentation layer
        // alone, so leaving the outgoing snapshot's model at opacity 1 made it
        // snap back to the full old screen for a frame the moment CoreAnimation
        // removed the fade — a visible flash of the previous month on every step.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayer.opacity = 0
        overlayLayer.transform = CATransform3DIdentity
        rootLayer.opacity = 1
        rootLayer.transform = CATransform3DIdentity
        CATransaction.commit()

        let duration: CFTimeInterval
        let timing = Motion.easeOut

        switch transition {
        case .none:
            finishTransition()
            return
        case .fade:
            duration = Motion.quick
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in self?.finishTransition() }
            Motion.animate(overlayLayer, keyPath: "opacity", from: 1, to: 0, duration: duration, timing: timing)
            Motion.animate(rootLayer, keyPath: "opacity", from: 0, to: 1, duration: duration, timing: timing)
            CATransaction.commit()
        case .push(let fromTrailing):
            duration = Motion.base
            let offset: CGFloat = 22
            let outgoingX = fromTrailing ? -offset : offset
            let incomingX = fromTrailing ? offset : -offset
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in self?.finishTransition() }
            overlayLayer.transform = CATransform3DMakeTranslation(outgoingX, 0, 0)
            Motion.animate(overlayLayer, keyPath: "transform.translation.x", from: 0, to: outgoingX, duration: duration, timing: timing)
            Motion.animate(overlayLayer, keyPath: "opacity", from: 1, to: 0, duration: duration, timing: timing)
            Motion.animate(rootLayer, keyPath: "transform.translation.x", from: incomingX, to: 0, duration: duration, timing: timing)
            Motion.animate(rootLayer, keyPath: "opacity", from: 0, to: 1, duration: duration, timing: timing)
            CATransaction.commit()
        case .zoom(let fromScale):
            duration = Motion.base
            let reciprocal = 1 / fromScale
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in self?.finishTransition() }
            overlayLayer.transform = CATransform3DMakeScale(reciprocal, reciprocal, 1)
            Motion.animate(overlayLayer, keyPath: "transform.scale", from: 1, to: reciprocal, duration: duration, timing: timing)
            Motion.animate(overlayLayer, keyPath: "opacity", from: 1, to: 0, duration: duration, timing: timing)
            Motion.animate(rootLayer, keyPath: "transform.scale", from: fromScale, to: 1, duration: duration, timing: timing)
            Motion.animate(rootLayer, keyPath: "opacity", from: 0, to: 1, duration: duration, timing: timing)
            CATransaction.commit()
        }
    }

    /// Transient confirmation shown for user actions (save, subscribe, …).
    /// Lives on the root view so it survives screen re-renders.
    func showToast(_ message: String) {
        toastLabel.stringValue = message
        if toastBox.superview == nil {
            view.addSubview(toastBox)
            NSLayoutConstraint.activate([
                toastBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                toastBox.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
            ])
        }
        view.addSubview(toastBox, positioned: .above, relativeTo: nil)
        toastTimer?.invalidate()
        toastBox.wantsLayer = true
        // The rise is a presentation-only layer animation, so the model transform
        // stays identity. Visibility rides on `alphaValue`, not on layer opacity:
        // driving opacity through a bare CABasicAnimation leaves the model value
        // where it started, and the box snapped back to invisible the moment the
        // animation was removed.
        Motion.animate(
            toastBox.layer, keyPath: "transform.translation.y",
            from: -8, to: 0, duration: Motion.quick, timing: Motion.easeOut
        )
        Motion.run(duration: Motion.quick, timing: Motion.easeOut) {
            self.toastBox.animator().alphaValue = 1
        }
        toastTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { [weak self] _ in
            guard let self else { return }
            Motion.animate(
                self.toastBox.layer, keyPath: "transform.translation.y",
                from: 0, to: -8, duration: Motion.quick, timing: Motion.easeOut
            )
            Motion.run(duration: Motion.quick, timing: Motion.easeOut) {
                self.toastBox.animator().alphaValue = 0
            }
        }
    }

    private func makeToast() -> NSView {
        let box = UI.roundedBox(fill: Palette.ink, radius: 999)
        box.alphaValue = 0
        box.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.font = Typography.sans(12.5, .medium)
        toastLabel.textColor = Palette.accentInk
        toastLabel.alignment = .center
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(toastLabel)
        NSLayoutConstraint.activate([
            toastLabel.topAnchor.constraint(equalTo: box.topAnchor, constant: 7),
            toastLabel.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -7),
            toastLabel.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16)
        ])
        return box
    }

    /// Sizes the popover to the current screen's content height so short
    /// screens don't leave bordered cards stretched into empty space.
    private func sizeToFit(_ screenView: NSView) {
        popoverWidthConstraint?.constant = currentPopoverWidth
        view.layoutSubtreeIfNeeded()
        let height = screenView.fittingSize.height
        preferredContentSize = NSSize(width: currentPopoverWidth, height: max(height, 1))
    }

    private var currentPopoverWidth: CGFloat {
        switch screen {
        case .luna: return Metrics.lunaPopoverWidth
        default: return Metrics.popoverWidth
        }
    }

    private var currentRootFill: NSColor {
        Palette.popoverBackground
    }

    func add(_ view: NSView, to stack: NSStackView) {
        stack.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    private func applyAppearance() {
        let appearance: NSAppearance?
        switch store.settings().colorScheme {
        case "light": appearance = NSAppearance(named: .aqua)
        case "dark": appearance = NSAppearance(named: .darkAqua)
        default: appearance = nil
        }
        view.appearance = appearance
        view.window?.appearance = appearance
    }
}
