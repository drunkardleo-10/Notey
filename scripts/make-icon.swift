import AppKit

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let canvas: CGFloat = 1024

func color(_ hex: UInt, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvas),
    pixelsHigh: Int(canvas),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
rep.size = NSSize(width: canvas, height: canvas)

NSGraphicsContext.saveGraphicsState()
let nsContext = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = nsContext
let ctx = nsContext.cgContext

let iconRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let squircle = NSBezierPath(roundedRect: iconRect, xRadius: 184, yRadius: 184)

ctx.saveGState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowBlurRadius = 26
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.set()
color(0xF6F4F9).setFill()
squircle.fill()
ctx.restoreGState()

ctx.saveGState()
squircle.addClip()
NSGradient(colors: [color(0xFFFFFF), color(0xEFECF4)])!.draw(in: iconRect, angle: -90)

struct NoteSpec {
    let center: NSPoint
    let side: CGFloat
    let top: UInt
    let bottom: UInt
    let fold: UInt
}

func drawNote(_ spec: NoteSpec) {
    let half = spec.side / 2
    let fold = spec.side * 0.24
    let radius = spec.side * 0.1
    let minX = spec.center.x - half
    let maxX = spec.center.x + half
    let minY = spec.center.y - half
    let maxY = spec.center.y + half

    let path = NSBezierPath()
    path.move(to: NSPoint(x: minX + radius, y: minY))
    path.line(to: NSPoint(x: maxX - fold, y: minY))
    path.line(to: NSPoint(x: maxX, y: minY + fold))
    path.line(to: NSPoint(x: maxX, y: maxY - radius))
    path.curve(to: NSPoint(x: maxX - radius, y: maxY), controlPoint1: NSPoint(x: maxX, y: maxY - radius / 2), controlPoint2: NSPoint(x: maxX - radius / 2, y: maxY))
    path.line(to: NSPoint(x: minX + radius, y: maxY))
    path.curve(to: NSPoint(x: minX, y: maxY - radius), controlPoint1: NSPoint(x: minX + radius / 2, y: maxY), controlPoint2: NSPoint(x: minX, y: maxY - radius / 2))
    path.line(to: NSPoint(x: minX, y: minY + radius))
    path.curve(to: NSPoint(x: minX + radius, y: minY), controlPoint1: NSPoint(x: minX, y: minY + radius / 2), controlPoint2: NSPoint(x: minX + radius / 2, y: minY))
    path.close()

    ctx.saveGState()
    let noteShadow = NSShadow()
    noteShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    noteShadow.shadowBlurRadius = 22
    noteShadow.shadowOffset = NSSize(width: 0, height: -2)
    noteShadow.set()
    color(spec.bottom).setFill()
    path.fill()
    ctx.restoreGState()

    ctx.saveGState()
    path.addClip()
    NSGradient(colors: [color(spec.top), color(spec.bottom)])!.draw(
        in: NSRect(x: minX, y: minY, width: spec.side, height: spec.side),
        angle: -80
    )
    ctx.restoreGState()

    let foldPath = NSBezierPath()
    foldPath.move(to: NSPoint(x: maxX - fold, y: minY))
    foldPath.line(to: NSPoint(x: maxX - fold, y: minY + fold))
    foldPath.line(to: NSPoint(x: maxX, y: minY + fold))
    foldPath.close()
    ctx.saveGState()
    let foldShadow = NSShadow()
    foldShadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    foldShadow.shadowBlurRadius = 8
    foldShadow.shadowOffset = NSSize(width: -2, height: 3)
    foldShadow.set()
    color(spec.fold).setFill()
    foldPath.fill()
    ctx.restoreGState()
}

ctx.translateBy(x: 512, y: 512)
ctx.scaleBy(x: 1.1, y: 1.1)
ctx.translateBy(x: -512, y: -512)

drawNote(NoteSpec(center: NSPoint(x: 512, y: 618), side: 400, top: 0xC58BF2, bottom: 0x9A5BE0, fold: 0x7F3FC9))
drawNote(NoteSpec(center: NSPoint(x: 512, y: 518), side: 400, top: 0xFFA06C, bottom: 0xFF7A45, fold: 0xE05A28))
drawNote(NoteSpec(center: NSPoint(x: 512, y: 418), side: 400, top: 0xFFE063, bottom: 0xFDC02E, fold: 0xE5A21C))

ctx.restoreGState()

let rim = NSBezierPath(roundedRect: iconRect.insetBy(dx: 1, dy: 1), xRadius: 183, yRadius: 183)
rim.lineWidth = 2
color(0x000000, 0.06).setStroke()
rim.stroke()

NSGraphicsContext.restoreGraphicsState()

let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: outputDir).appendingPathComponent("icon-1024.png"))
