import SwiftUI

struct EdgeAnchorView: View {
    let edge: DeckEdge
    let isDeckHovered: Bool
    var onAddNote: (() -> Void)?
    var onGripChanged: (() -> Void)?
    var onGripEnded: (() -> Void)?
    var onGripHover: ((Bool) -> Void)?

    @State private var isGripDragging = false
    @State private var isGripHovered = false

    var body: some View {
        Group {
            if edge.isVertical {
                VStack(spacing: 6) {
                    addButton
                    gripHandle
                }
                .frame(width: NoteyLayout.tabPeekingWidth, height: NoteyLayout.anchorHeight - 2)
            } else {
                HStack(spacing: 6) {
                    addButton
                    gripHandle
                }
                .frame(width: NoteyLayout.anchorHeight - 2, height: NoteyLayout.tabPeekingWidth)
            }
        }
    }

    private var addButton: some View {
        Button(action: { onAddNote?() }) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.96))
                        .shadow(
                            color: Color.black.opacity(0.14),
                            radius: 3, x: 0, y: 1.5
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.textPrimary.opacity(0.12), lineWidth: 0.8)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Add new note")
        .frame(width: 32, height: 32)
    }

    private var gripHandle: some View {
        let columns = edge.isVertical ? 2 : 3
        let rows = edge.isVertical ? 3 : 2

        return VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 3) {
                    ForEach(0..<columns, id: \.self) { _ in
                        Circle().fill(Color.white.opacity(0.85)).frame(width: 3.5, height: 3.5)
                    }
                }
            }
        }
        .frame(width: edge.isVertical ? 26 : 30, height: edge.isVertical ? 28 : 24)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.32))
        )
        .contentShape(Rectangle())
        .onHover { inside in
            isGripHovered = inside
            onGripHover?(inside)
            if isGripDragging { return }
            if inside {
                NSCursor.openHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { _ in
                    isGripDragging = true
                    NSCursor.closedHand.set()
                    onGripChanged?()
                }
                .onEnded { _ in
                    isGripDragging = false
                    onGripEnded?()
                }
        )
        .accessibilityLabel("Drag to move the deck")
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.noteyQuick, value: configuration.isPressed)
    }
}
