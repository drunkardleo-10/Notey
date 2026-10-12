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

    static let snapThreshold: CGFloat = 72

    static func idleLength(noteCount: Int) -> CGFloat {
        let count = max(1, noteCount)
        let spacing: CGFloat = 5.5
        let padding: CGFloat = 12
        return CGFloat(count) * NoteyLayout.tabIdleHeight + CGFloat(count - 1) * spacing + padding
    }

    static func hoverLength(noteCount: Int) -> CGFloat {
        let count = max(1, noteCount)
        let step: CGFloat = 62
        let tabsLength = CGFloat(count - 1) * step + NoteyLayout.tabExpandedHeight
        let anchorSpacing: CGFloat = 16
        return tabsLength + NoteyLayout.anchorHeight + anchorSpacing + 30
    }

    private static func alongRange(_ screenFrame: CGRect, edge: DeckEdge) -> (mid: CGFloat, length: CGFloat) {
        edge.isVertical
            ? (screenFrame.midY, screenFrame.height)
            : (screenFrame.midX, screenFrame.width)
    }

    static func clampedAlongOffset(
        _ offset: CGFloat,
        edge: DeckEdge,
        noteCount: Int,
        for window: NSWindow? = nil
    ) -> CGFloat {
        let f = screen(for: window).frame
        let total = edge.isVertical ? f.height : f.width
        let limit = max((total - hoverLength(noteCount: noteCount)) / 2.0 - 8, 0)
        return min(max(offset, -limit), limit)
    }

    static func edgeDeckMoveFrame(for window: NSWindow? = nil) -> CGRect {
        screen(for: window).frame
    }

    private static func deckFrame(
        for window: NSWindow?,
        edge: DeckEdge,
        depth: CGFloat,
        length: CGFloat,
        alongOffset: CGFloat
    ) -> CGRect {
        let scr = screen(for: window)
        let f = scr.frame
        let visible = scr.visibleFrame
        let range = alongRange(f, edge: edge)
        let alongStart = min(
            max(range.mid + alongOffset - length / 2.0, (edge.isVertical ? f.minY : f.minX) + 8),
            (edge.isVertical ? f.maxY : f.maxX) - length - 8
        )

        switch edge {
        case .right:
            return CGRect(x: f.maxX - depth, y: alongStart, width: depth, height: length)
        case .left:
            return CGRect(x: f.minX, y: alongStart, width: depth, height: length)
        case .top:
            return CGRect(x: alongStart, y: visible.maxY - depth, width: length, height: depth)
        case .bottom:
            return CGRect(x: alongStart, y: visible.minY, width: length, height: depth)
        }
    }

    static func edgeDeckIdleFrame(
        for window: NSWindow? = nil,
        noteCount: Int = 3,
        edge: DeckEdge = .right,
        alongOffset: CGFloat = 0
    ) -> CGRect {
        deckFrame(
            for: window,
            edge: edge,
            depth: NoteyLayout.deckIdleWidth,
            length: idleLength(noteCount: noteCount),
            alongOffset: alongOffset
        )
    }

    static func edgeDeckHoverFrame(
        for window: NSWindow? = nil,
        noteCount: Int = 3,
        edge: DeckEdge = .right,
        alongOffset: CGFloat = 0
    ) -> CGRect {
        deckFrame(
            for: window,
            edge: edge,
            depth: NoteyLayout.deckHoverWidth,
            length: hoverLength(noteCount: noteCount),
            alongOffset: alongOffset
        )
    }

    static func dropTarget(
        point: CGPoint,
        in size: CGSize,
        noteCount: Int,
        for window: NSWindow? = nil
    ) -> (edge: DeckEdge, offset: CGFloat) {
        let distances: [(DeckEdge, CGFloat)] = [
            (.left, point.x),
            (.right, size.width - point.x),
            (.top, point.y),
            (.bottom, size.height - point.y)
        ]
        let edge = distances.min(by: { $0.1 < $1.1 })?.0 ?? .right
        let raw = edge.isVertical ? size.height / 2 - point.y : point.x - size.width / 2
        let snapped = abs(raw) < snapThreshold ? 0 : raw
        let offset = clampedAlongOffset(snapped, edge: edge, noteCount: noteCount, for: window)
        return (edge, offset)
    }

    static func editorFrame(
        for window: NSWindow? = nil,
        edge: DeckEdge,
        alongOffset: CGFloat
    ) -> CGRect {
        let scr = screen(for: window)
        let f = scr.frame
        let visible = scr.visibleFrame
        let w = NoteyLayout.editorWidth
        let h = NoteyLayout.editorHeight
        let gap: CGFloat = 16
        let inset = NoteyLayout.deckIdleWidth + gap

        func clampX(_ value: CGFloat) -> CGFloat {
            min(max(value, f.minX + 12), f.maxX - w - 12)
        }
        func clampY(_ value: CGFloat) -> CGFloat {
            min(max(value, visible.minY + 12), visible.maxY - h - 12)
        }

        switch edge {
        case .right:
            return CGRect(x: f.maxX - inset - w, y: clampY(f.midY + alongOffset - h / 2), width: w, height: h)
        case .left:
            return CGRect(x: f.minX + inset, y: clampY(f.midY + alongOffset - h / 2), width: w, height: h)
        case .top:
            return CGRect(x: clampX(f.midX + alongOffset - w / 2), y: visible.maxY - inset - h, width: w, height: h)
        case .bottom:
            return CGRect(x: clampX(f.midX + alongOffset - w / 2), y: visible.minY + inset, width: w, height: h)
        }
    }
}
