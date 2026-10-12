import AppKit

let width: CGFloat = 660
let height: CGFloat = 400
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func color(_ hex: UInt, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func draw(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(width * scale),
        pixelsHigh: Int(height * scale),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let bounds = NSRect(x: 0, y: 0, width: width, height: height)
    NSGradient(colors: [color(0xFAF6EE), color(0xEBE3D7)])!.draw(in: bounds, angle: -60)

    let glow = NSGradient(colors: [color(0x4A9EA8, 0.16), color(0x4A9EA8, 0)])!
    glow.draw(fromCenter: NSPoint(x: 330, y: 230), radius: 0, toCenter: NSPoint(x: 330, y: 230), radius: 260, options: [])

    let tabColors: [UInt] = [0xFDC844, 0xFF8A80, 0x80E5D0, 0x82B1FF, 0xCE93D8]
    for (index, hex) in tabColors.enumerated() {
        let tab = NSBezierPath(
            roundedRect: NSRect(x: width - 10, y: 150 + CGFloat(index) * 22, width: 20, height: 16),
            xRadius: 5,
            yRadius: 5
        )
        color(hex).setFill()
        tab.fill()
    }

    let title = NSAttributedString(
        string: "Install Notey",
        attributes: [
            .font: NSFont.systemFont(ofSize: 26, weight: .heavy),
            .foregroundColor: color(0x2C2622)
        ]
    )
    title.draw(at: NSPoint(x: (width - title.size().width) / 2, y: 336))

    let subtitle = NSAttributedString(
        string: "Drag Notey into your Applications folder",
        attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: color(0x8C827A)
        ]
    )
    subtitle.draw(at: NSPoint(x: (width - subtitle.size().width) / 2, y: 310))

    let arrow = NSBezierPath()
    arrow.lineWidth = 4
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: 268, y: 168))
    arrow.line(to: NSPoint(x: 392, y: 168))
    arrow.move(to: NSPoint(x: 372, y: 188))
    arrow.line(to: NSPoint(x: 394, y: 168))
    arrow.line(to: NSPoint(x: 372, y: 148))
    color(0x2C2622, 0.75).setStroke()
    arrow.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for (name, scale) in [("background.png", CGFloat(1)), ("background@2x.png", CGFloat(2))] {
    let data = draw(scale: scale).representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: outputDir).appendingPathComponent(name))
}
