import AppKit
import XCTest
@testable import DaylightMenuBarKit

final class SolarTermIconGlyphsTests: XCTestCase {
    func testSolarTermIconGlyphsShapesExistForAllTerms() {
        for term in SolarTermIconArt.termNames {
            XCTAssertFalse(SolarTermIconGlyphs.shapes(for: term, in: CGRect(x: 0, y: 0, width: 24, height: 24)).isEmpty, term)
        }
    }

    func testSolarTermIconGlyphsShapesAreEmptyForUnknownTerm() {
        XCTAssertTrue(SolarTermIconGlyphs.shapes(for: "未知节气", in: CGRect(x: 0, y: 0, width: 24, height: 24)).isEmpty)
        XCTAssertTrue(SolarTermIconGlyphs.shapes(for: "", in: CGRect(x: 0, y: 0, width: 24, height: 24)).isEmpty)
    }

    func testSolarTermIconGlyphsUsesNoMoreThanSixStrokeElementsPerTerm() {
        for term in SolarTermIconArt.termNames {
            let strokeCount = SolarTermIconGlyphs.shapes(for: term, in: CGRect(x: 0, y: 0, width: 24, height: 24)).filter { shape in
                if case .stroke = shape.mode { return true }
                return false
            }.count
            XCTAssertLessThanOrEqual(strokeCount, 6, term)
        }
    }

    @MainActor func testSolarTermIconGlyphsRenderedGlyphsArePairwiseDistinct() throws {
        var signatures: [Data: String] = [:]

        for term in SolarTermIconArt.termNames {
            let signature = try renderedIconSignature(for: term)
            if let duplicate = signatures[signature] {
                XCTFail("\(term) rendered identically to \(duplicate)")
            }
            signatures[signature] = term
        }

        XCTAssertEqual(signatures.count, SolarTermIconArt.termNames.count)
    }

    func testBothMastersFitInsideTheirCanvas() {
        for variant in [SolarTermIconVariant.small, .large] {
            let rect = CGRect(x: 0, y: 0, width: 48, height: 48)
            for term in SolarTermIconArt.termNames {
                for shape in SolarTermIconGlyphs.shapes(for: term, in: rect, variant: variant) {
                    XCTAssertTrue(rect.contains(shape.path.bounds), "\(term) \(variant)")
                }
            }
        }
    }

    @MainActor func testLargeMastersRenderDistinctGeometry() throws {
        var signatures = Set<Data>()
        for term in SolarTermIconArt.termNames {
            let large = try renderedIconSignature(for: term, variant: .large)
            XCTAssertNotEqual(large, try renderedIconSignature(for: term), term)
            signatures.insert(large)
        }
        XCTAssertEqual(signatures.count, 24)
    }

    @MainActor private func renderedIconSignature(for term: String, variant: SolarTermIconVariant = .small) throws -> Data {
        let pixels = 24
        let bytesPerRow = pixels * 4
        let rep = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixels,
            pixelsHigh: pixels,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: bytesPerRow,
            bitsPerPixel: 32
        ))
        let context = try XCTUnwrap(NSGraphicsContext(bitmapImageRep: rep))
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context
        context.shouldAntialias = true
        context.cgContext.clear(CGRect(x: 0, y: 0, width: pixels, height: pixels))

        Palette.shadow.setStroke()
        Palette.shadow.setFill()
        for shape in SolarTermIconGlyphs.shapes(for: term, in: CGRect(x: 1.5, y: 1.5, width: 21, height: 21), variant: variant) {
            let color = SolarTermIconPalette.color(for: shape.tone, dark: false, fallback: Palette.shadow)
            color.withAlphaComponent(shape.opacity).setStroke()
            color.withAlphaComponent(shape.opacity).setFill()
            shape.path.lineWidth = (shape.lineWidth ?? 1.6) * 21 / 24
            shape.path.lineCapStyle = .round
            shape.path.lineJoinStyle = .round
            switch shape.mode {
            case .stroke: shape.path.stroke()
            case .fill: shape.path.fill()
            }
        }

        return Data(bytes: try XCTUnwrap(rep.bitmapData), count: rep.bytesPerRow * rep.pixelsHigh)
    }
}
