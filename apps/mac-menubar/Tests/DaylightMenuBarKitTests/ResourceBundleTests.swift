// Regression coverage for locating bundled resources inside a packaged app.
// Exports: ResourceBundleTests
// Deps: XCTest, DaylightMenuBarKit ResourceBundle

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class ResourceBundleTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ResourceBundleTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// Packaged layout: resources live in Contents/Resources, where SwiftPM's
    /// own accessor never looks (App Review crash, 2.0.3).
    func testFindsBundleInsidePackagedAppResources() throws {
        let app = try makeApp(withResourceBundle: true)
        let bundle = try XCTUnwrap(ResourceBundle.locate(mainBundle: app))
        XCTAssertNotNil(bundle.url(forResource: "IBMPlexSans-VF", withExtension: "ttf"))
    }

    /// A packaged app missing its resources must degrade, not fatalError.
    func testPackagedAppWithoutResourcesReturnsNil() throws {
        let app = try makeApp(withResourceBundle: false)
        XCTAssertNil(ResourceBundle.locate(mainBundle: app))
    }

    func testSourcesNeverUseSwiftPMModuleAccessorDirectly() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources")
        let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)!
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" && $0.lastPathComponent != "ResourceBundle.swift" }
        XCTAssertFalse(files.isEmpty)
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            XCTAssertFalse(text.contains("Bundle.module"), "\(file.lastPathComponent) uses Bundle.module; use ResourceBundle.kit")
        }
    }

    private func makeApp(withResourceBundle: Bool) throws -> Bundle {
        let contents = root.appendingPathComponent("Daylight.app/Contents")
        let resources = contents.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let info: [String: Any] = ["CFBundleIdentifier": "test.daylight.\(UUID().uuidString)", "CFBundlePackageType": "APPL"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: contents.appendingPathComponent("Info.plist"))
        if withResourceBundle {
            let source = try XCTUnwrap(ResourceBundle.kit).bundleURL
            try FileManager.default.copyItem(at: source, to: resources.appendingPathComponent(ResourceBundle.name))
        }
        return try XCTUnwrap(Bundle(url: root.appendingPathComponent("Daylight.app")))
    }
}
