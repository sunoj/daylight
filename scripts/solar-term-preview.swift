// AppKit contact sheets. Invoked by generate-solar-term-icons.mjs --png.
// SolarTermIconShape and SolarTermIconGlyphs are prepended by the generator.
let terms = ["立春", "雨水", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至", "小寒", "大寒"]
func label(_ text: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: NSColor) {
    (text as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: NSFont.systemFont(ofSize: size), .foregroundColor: color])
}
func glyph(_ term: String, size: CGFloat, variant: SolarTermIconVariant, x: CGFloat, y: CGFloat, dark: Bool) {
    let color = NSColor(calibratedWhite: dark ? 0.88 : 0.22, alpha: 1)
    let rect = NSRect(x: x, y: y, width: size, height: size)
    for shape in SolarTermIconGlyphs.shapes(for: term, in: rect, variant: variant) {
        SolarTermIconPalette.color(for: shape.tone, dark: dark, fallback: color).withAlphaComponent(shape.opacity).setStroke()
        SolarTermIconPalette.color(for: shape.tone, dark: dark, fallback: color).withAlphaComponent(shape.opacity).setFill()
        shape.path.lineWidth = (shape.lineWidth ?? 1.6) * size / 24
        shape.path.lineCapStyle = .round
        shape.path.lineJoinStyle = .round
        switch shape.mode { case .stroke: shape.path.stroke(); case .fill: shape.path.fill() }
    }
}
func sheet(largeOnly: Bool) throws {
    let width = 1100, height = largeOnly ? 1040 : 900
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width * 2, pixelsHigh: height * 2, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: 2, y: 2)
    NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    label(largeOnly ? "DAYLIGHT / BOTANICAL SOLAR TERMS" : "DAYLIGHT / 24 SOLAR TERMS", 38, CGFloat(height - 50), 23, .black)
    label(largeOnly ? "Detailed masters · enlarged 2× / actual 48 px on dark" : "Optical masters · 48 px detail / 20 px compact · light + dark", 38, CGFloat(height - 80), 13, .gray)
    for (index, term) in terms.enumerated() {
        let x = CGFloat(index % 6) * 174 + 30
        let y = CGFloat(3 - index / 6) * (largeOnly ? 222 : 188) + 36
        let cardHeight: CGFloat = largeOnly ? 208 : 172
        NSColor.white.setFill()
        NSBezierPath(roundedRect: NSRect(x: x, y: y, width: 160, height: cardHeight), xRadius: 10, yRadius: 10).fill()
        NSColor(calibratedWhite: 0.15, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: x+8, y: y+8, width: 144, height: 62), xRadius: 6, yRadius: 6).fill()
        label(term, x+13, y+cardHeight-29, 14, .black)
        label(String(format: "%02d", index+1), x+126, y+cardHeight-26, 10, .gray)
        if largeOnly {
            glyph(term, size: 96, variant: .large, x: x+32, y: y+77, dark: false)
            glyph(term, size: 48, variant: .large, x: x+56, y: y+15, dark: true)
            label("48", x+17, y+34, 9, .gray)
        } else {
            for dark in [false,true] {
                let row: CGFloat = dark ? 15 : 84
                glyph(term, size: 48, variant: .large, x: x+22, y: y+row, dark: dark)
                glyph(term, size: 20, variant: .small, x: x+109, y: y+row+14, dark: dark)
            }
        }
    }
    let name = largeOnly ? "large-preview.png" : "preview.png"
    let url = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent(name)
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}
try sheet(largeOnly: false)
try sheet(largeOnly: true)
