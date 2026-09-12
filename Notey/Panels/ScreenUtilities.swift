import AppKit

struct ScreenGeometry {
    let origin: CGPoint
    let size: CGSize

    var x: CGFloat { origin.x }
    var y: CGFloat { origin.y }
    var width: CGFloat { size.width }
    var height: CGFloat { size.height }
    var frame: CGRect { CGRect(origin: origin, size: size) }
}

enum ScreenUtilities {
    static func screen(for window: NSWindow? = nil) -> NSScreen {
        if let winScreen = window?.screen {
            return winScreen
        }
        let mouseLocation = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            let f = screen.frame
            if mouseLocation.x >= f.minX && mouseLocation.x <= f.maxX &&
               mouseLocation.y >= f.minY && mouseLocation.y <= f.maxY {
                return screen
            }
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    static func cursorScreenGeometry(for window: NSWindow? = nil) -> ScreenGeometry? {
        let scr = screen(for: window)
        return ScreenGeometry(origin: scr.frame.origin, size: scr.frame.size)
    }

    static func cursorScreenVisibleFrame(for window: NSWindow? = nil) -> CGRect? {
        let scr = screen(for: window)
        return scr.visibleFrame
    }

    static func centeredFrame(width: CGFloat, height: CGFloat, for window: NSWindow? = nil) -> CGRect? {
        guard let geo = cursorScreenGeometry(for: window) else { return nil }
        let x = geo.x + (geo.width - width) / 2.0
        let y = geo.y + (geo.height - height) / 2.0
        return CGRect(x: x, y: y, width: width, height: height)
    }

    static func edgeDeckFrame(for window: NSWindow? = nil, width: CGFloat, heightRatio: CGFloat = 0.85) -> CGRect {
        let scr = screen(for: window)
        let f = scr.frame
        let h = f.height * heightRatio
        let x = f.origin.x + f.width - width
        let y = f.origin.y + (f.height - h) / 2.0
        return CGRect(x: x, y: y, width: width, height: h)
    }

    static func edgeDeckIdleFrame(for window: NSWindow? = nil, noteCount: Int = 3) -> CGRect {
        let scr = screen(for: window)
        let f = scr.frame
        let count = max(1, noteCount)
        let pillHeight = NoteyLayout.tabIdleHeight
        let spacing: CGFloat = 5.5
        let padding: CGFloat = 12
        let h = CGFloat(count) * pillHeight + CGFloat(count - 1) * spacing + padding
        let x = f.origin.x + f.width - NoteyLayout.deckIdleWidth
        let y = f.origin.y + (f.height - h) / 2.0
        return CGRect(x: x, y: y, width: NoteyLayout.deckIdleWidth, height: h)
    }

    static func edgeDeckHoverFrame(for window: NSWindow? = nil, noteCount: Int = 3) -> CGRect {
        let scr = screen(for: window)
        let f = scr.frame
        let count = max(1, noteCount)
        let step: CGFloat = 62
        let baseHeight = NoteyLayout.tabExpandedHeight
        let tabsHeight = CGFloat(count - 1) * step + baseHeight
        let anchorHeight: CGFloat = 44
        let anchorSpacing: CGFloat = 16
        let h = tabsHeight + anchorHeight + anchorSpacing + 30
        let x = f.origin.x + f.width - NoteyLayout.deckHoverWidth
        let y = f.origin.y + (f.height - h) / 2.0
        return CGRect(x: x, y: y, width: NoteyLayout.deckHoverWidth, height: h)
    }
}
