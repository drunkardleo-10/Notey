import SwiftUI
import AppKit

struct EditorHeaderView: View {
    @Binding var title: String
    let isPinned: Bool
    let autosaveStatus: String
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onTogglePin: (() -> Void)?
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                NativeCloseButton(action: { onClose?() })

                TextField("Untitled note", text: $title)
                    .textFieldStyle(.plain)
                    .font(NoteyFonts.ui(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    WindowDragGripView()
                        .frame(width: 28, height: 28)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.openHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .accessibilityLabel("Drag note window")

                    Button(action: { onTogglePin?() }) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(isPinned ? Color.textPrimary : Color.textPrimary.opacity(0.55))
                            .rotationEffect(.degrees(isPinned ? 0 : 45))
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(isPinned ? Color.textPrimary.opacity(0.14) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPinned ? "Unpin note" : "Pin note")
                }
            }
            .padding(.init(top: 12, leading: 16, bottom: 8, trailing: 16))

            Rectangle()
                .fill(Color.textPrimary.opacity(0.08))
                .frame(height: 1)
        }
    }
}

struct NativeCloseButton: View {
    var action: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xFF5F56))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: 0xE0443E).opacity(0.85), lineWidth: 0.5)
                    )

                Image(systemName: "xmark")
                    .font(.system(size: 6.5, weight: .bold))
                    .foregroundStyle(Color(hex: 0x4D0000).opacity(isHovered ? 1.0 : 0.65))
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel("Close note")
    }
}

struct WindowDragGripView: NSViewRepresentable {
    func makeNSView(context: Context) -> DragGripNSView {
        DragGripNSView()
    }

    func updateNSView(_ nsView: DragGripNSView, context: Context) {}
}

final class DragGripNSView: NSView {
    private var isHovered: Bool = false
    private var isCursorPushed: Bool = false
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .cursorUpdate,
            .activeAlways,
            .inVisibleRect
        ]
        let newArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(newArea)
        trackingArea = newArea
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.openHand.set()
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
        if !isCursorPushed {
            NSCursor.openHand.push()
            isCursorPushed = true
        }
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
        if isCursorPushed {
            NSCursor.pop()
            isCursorPushed = false
        }
        needsDisplay = true
    }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }
        if isCursorPushed {
            NSCursor.pop()
            isCursorPushed = false
        }
        NSCursor.closedHand.push()
        window.performDrag(with: event)
        NSCursor.pop()
        if isHovered {
            NSCursor.openHand.push()
            isCursorPushed = true
        }
        window.invalidateCursorRects(for: self)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isHovered {
            let bgRect = bounds.insetBy(dx: 2, dy: 2)
            let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 6, yRadius: 6)
            NSColor(srgbRed: 0x2C/255, green: 0x26/255, blue: 0x22/255, alpha: 0.08).setFill()
            bgPath.fill()
        }

        let dotColor = isHovered
            ? NSColor(srgbRed: 0x2C/255, green: 0x26/255, blue: 0x22/255, alpha: 0.75)
            : NSColor(srgbRed: 0x2C/255, green: 0x26/255, blue: 0x22/255, alpha: 0.45)
        dotColor.setFill()

        let dotSize: CGFloat = 3.2
        let spacing: CGFloat = 2.5
        let totalWidth = dotSize * 2 + spacing
        let totalHeight = dotSize * 3 + spacing * 2
        let startX = (bounds.width - totalWidth) / 2.0
        let startY = (bounds.height - totalHeight) / 2.0

        for col in 0..<2 {
            for row in 0..<3 {
                let x = startX + CGFloat(col) * (dotSize + spacing)
                let y = startY + CGFloat(row) * (dotSize + spacing)
                let dotRect = NSRect(x: x, y: y, width: dotSize, height: dotSize)
                let path = NSBezierPath(ovalIn: dotRect)
                path.fill()
            }
        }
    }
}
