import SwiftUI

struct DeckMoveOverlay<Ghost: View>: View {
    let colors: [Color]
    let point: CGPoint
    let sway: Double
    let settling: Bool
    let previewEdge: DeckEdge
    let previewOffset: CGFloat
    let ghost: Ghost

    @State private var appeared = false

    private var cards: [Color] {
        colors.isEmpty ? [Color.noteYellow] : colors
    }

    private var edgeOpposite: UnitPoint {
        switch previewEdge {
        case .left: return .trailing
        case .right: return .leading
        case .top: return .bottom
        case .bottom: return .top
        }
    }

    private var alongShift: CGSize {
        previewEdge.isVertical
            ? CGSize(width: 0, height: -previewOffset)
            : CGSize(width: previewOffset, height: 0)
    }

    var body: some View {
        ZStack {
            edgeShadow
            landingGhost
            miniStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.66)) {
                appeared = true
            }
        }
    }

    private var edgeShadow: some View {
        let length: CGFloat = 220
        let depth: CGFloat = 64
        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.black.opacity(0.42), Color.black.opacity(0)],
                    startPoint: previewEdge.unitPoint,
                    endPoint: edgeOpposite
                )
            )
            .frame(
                width: previewEdge.isVertical ? depth : length,
                height: previewEdge.isVertical ? length : depth
            )
            .mask(
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .padding(previewEdge.isVertical ? .vertical : .horizontal, 0)
                    .blur(radius: 14)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: previewEdge.alignment)
            .offset(alongShift)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: previewOffset)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: previewEdge)
            .opacity(appeared ? 1 : 0)
    }

    private var landingGhost: some View {
        ghost
            .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: previewEdge.alignment)
            .offset(alongShift)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: previewOffset)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: previewEdge)
            .opacity(appeared ? 0.9 : 0)
    }

    private var miniStack: some View {
        ZStack {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, color in
                let depth = Double(cards.count - 1 - index)
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(color)
                    .frame(width: 52, height: 40)
                    .shadow(color: Color.black.opacity(0.28), radius: 6, x: 0, y: 4)
                    .rotationEffect(.degrees(appeared ? (depth - 1) * 9 : 0))
                    .offset(
                        x: appeared ? CGFloat(depth) * -5 : 0,
                        y: appeared ? CGFloat(depth) * 3 : 0
                    )
                    .zIndex(Double(index))
            }
        }
        .scaleEffect(appeared ? (settling ? 0.7 : 1) : 2.4)
        .opacity(appeared ? (settling ? 0.15 : 1) : 0)
        .rotationEffect(.degrees(sway), anchor: .top)
        .animation(.interpolatingSpring(stiffness: 70, damping: 5.5), value: sway)
        .position(point)
    }
}
