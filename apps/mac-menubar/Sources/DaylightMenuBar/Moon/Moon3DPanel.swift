// 3D moon feature — SceneKit model + locally observed position.
// Requests location only here (on appear), per the design's privacy model.
// Exports: Moon3DPanel, MoonObservationDateResolver
// Deps: AppKit, SceneKit, LocationService, DaylightStore, MoonObservationCalculator, DesignSystem

import AppKit
import SceneKit

enum MoonObservationDateResolver {
    static func observationDate(
        for displayDate: LocalDate,
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Date {
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let today = LocalDate(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
        // Alt/Az are time-of-day dependent: use the live instant only when showing today.
        if displayDate == today { return now }
        return displayDate.noonDate(using: calendar)
    }
}

final class Moon3DPanel: NSStackView {
    private let displayDate: LocalDate
    private let onClose: () -> Void
    private let sceneView = SCNView()
    private let locationService: LocationService
    private let calculator = MoonObservationCalculator()
    private let lunarCalendar = LunarCalendar()
    private let fallback = ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)
    private let moonNode = SCNNode()
    private let sunNode = SCNNode()
    private let phaseLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")

    init(displayDate: LocalDate, requestLocation: Bool, store: DaylightStore = DaylightStore(), onClose: @escaping () -> Void) {
        self.displayDate = displayDate
        self.onClose = onClose
        self.locationService = LocationService(store: store)
        super.init(frame: .zero)
        orientation = .vertical
        spacing = 12
        alignment = .leading
        edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 10, right: 4)
        build()
        configureScene()
        locationService.onStateChanged = { [weak self] state in
            DispatchQueue.main.async { self?.update(for: state) }
        }
        if requestLocation {
            locationService.start()
        } else {
            update(for: .unavailable(L("未授权")))
        }
    }

    required init?(coder: NSCoder) { nil }

    private func build() {
        full(header())
        full(sceneCard())
        full(detailCard())
        full(statusRow())
    }

    private func full(_ view: NSView) {
        addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }

    private func header() -> NSView {
        let title = UI.label(L("3D 月相"), font: Typography.sans(20, .semibold), color: Palette.ink)
        let back = RowButton(target: self, action: #selector(close))
        let tile = UI.roundedBox(fill: Palette.surface2, radius: 14)
        tile.widthAnchor.constraint(equalToConstant: 28).isActive = true
        tile.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let glyph = NSImageView(image: NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back") ?? NSImage())
        glyph.contentTintColor = Palette.ink2
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])
        back.addContentView(tile)
        let row = NSStackView(views: [title, spacer(), back])
        row.orientation = .horizontal
        row.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return row
    }

    private func sceneCard() -> NSView {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        return UI.card(sceneView)
    }

    private func detailCard() -> NSView {
        phaseLabel.font = Typography.sans(15, .semibold)
        phaseLabel.textColor = Palette.ink
        detailLabel.font = Typography.mono(12)
        detailLabel.textColor = Palette.ink2
        detailLabel.maximumNumberOfLines = 2
        let stack = NSStackView(views: [phaseLabel, detailLabel])
        stack.orientation = .vertical
        stack.spacing = 5
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        return UI.card(stack)
    }

    private func statusRow() -> NSView {
        statusLabel.font = Typography.mono(10.5)
        statusLabel.textColor = Palette.ink4
        let row = NSStackView(views: [statusLabel])
        row.orientation = .horizontal
        row.edgeInsets = NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        return row
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    // MARK: Scene

    private func configureScene() {
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .clear
        moonNode.addChildNode(loadMoonModel() ?? fallbackSphere())
        sceneView.scene?.rootNode.addChildNode(moonNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 3.2)
        sceneView.scene?.rootNode.addChildNode(camera)

        let ambient = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 90
        ambient.light = ambientLight
        sceneView.scene?.rootNode.addChildNode(ambient)

        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.intensity = 1_200
        sunNode.light = sunLight
        sceneView.scene?.rootNode.addChildNode(sunNode)
    }

    /// Loads the bundled NASA LRO moon model, normalized to unit radius.
    private func loadMoonModel() -> SCNNode? {
        guard let url = Bundle.module.url(forResource: "Moon_NASA_LRO_Flat_Small", withExtension: "usdz"),
              let scene = try? SCNScene(url: url, options: nil) else {
            return nil
        }
        let container = SCNNode()
        scene.rootNode.childNodes.forEach { container.addChildNode($0.clone()) }
        let model = container.flattenedClone()
        let (center, radius) = model.boundingSphere
        if radius > 0 {
            model.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
            let scale = 1 / radius
            model.scale = SCNVector3(scale, scale, scale)
        }
        return model
    }

    private func fallbackSphere() -> SCNNode {
        let sphere = SCNSphere(radius: 1)
        sphere.segmentCount = 64
        sphere.firstMaterial?.diffuse.contents = NSColor(white: 0.74, alpha: 1)
        sphere.firstMaterial?.roughness.contents = 0.95
        return SCNNode(geometry: sphere)
    }

    private func update(for state: LocationState) {
        let location = location(from: state)
        let observation = calculator.observation(
            at: MoonObservationDateResolver.observationDate(for: displayDate),
            location: location
        )
        phaseLabel.stringValue = MoonNames.phaseCN(observation.phaseAngleDegrees)
        let percent = Int((observation.illuminatedFraction * 100).rounded())
        detailLabel.stringValue = "\(percent)% \(L("照亮")) · \(L("月龄")) \(fmt(observation.ageDays))d\nAlt \(fmt(observation.altitudeDegrees))° · Az \(fmt(observation.azimuthDegrees))°"
        statusLabel.stringValue = statusText(state)
        moonNode.eulerAngles = SCNVector3(0, 0, Float(observation.parallacticAngleDegrees * .pi / 180))
        // +180° so a full moon (phase 180°) lights the face toward the camera.
        sunNode.eulerAngles = SCNVector3(0, Float((observation.phaseAngleDegrees + 180) * .pi / 180), 0)
    }

    private func location(from state: LocationState) -> ObserverLocation {
        if case let .authorized(location) = state { return location }
        return fallback
    }

    private func statusText(_ state: LocationState) -> String {
        switch state {
        case .waiting: return L("正在获取位置…")
        case .authorized: return L("使用当前位置")
        case let .unavailable(reason): return reason
        }
    }

    private func fmt(_ value: Double) -> String { String(format: "%.1f", value) }

    @objc private func close() { onClose() }
}
