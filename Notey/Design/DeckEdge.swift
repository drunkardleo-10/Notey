import SwiftUI

enum DeckEdge: String, CaseIterable, Sendable {
    case left
    case right
    case top
    case bottom

    var isVertical: Bool {
        self == .left || self == .right
    }

    var alignment: Alignment {
        switch self {
        case .left: return .leading
        case .right: return .trailing
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    var farAlignment: Alignment {
        switch self {
        case .left: return .trailing
        case .right: return .leading
        case .top: return .bottom
        case .bottom: return .top
        }
    }

    var unitPoint: UnitPoint {
        switch self {
        case .left: return .leading
        case .right: return .trailing
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    var outward: CGSize {
        switch self {
        case .left: return CGSize(width: -1, height: 0)
        case .right: return CGSize(width: 1, height: 0)
        case .top: return CGSize(width: 0, height: -1)
        case .bottom: return CGSize(width: 0, height: 1)
        }
    }

    func along(_ size: CGSize) -> CGFloat {
        isVertical ? size.height : size.width
    }

    func alongOffset(_ value: CGFloat) -> CGSize {
        isVertical ? CGSize(width: 0, height: value) : CGSize(width: value, height: 0)
    }

    func farCornerRadii(_ first: CGFloat, _ second: CGFloat) -> RectangleCornerRadii {
        switch self {
        case .right:
            return RectangleCornerRadii(topLeading: first, bottomLeading: second, bottomTrailing: 0, topTrailing: 0)
        case .left:
            return RectangleCornerRadii(topLeading: 0, bottomLeading: 0, bottomTrailing: second, topTrailing: first)
        case .bottom:
            return RectangleCornerRadii(topLeading: first, bottomLeading: 0, bottomTrailing: 0, topTrailing: second)
        case .top:
            return RectangleCornerRadii(topLeading: 0, bottomLeading: first, bottomTrailing: second, topTrailing: 0)
        }
    }
}

struct AxisStack<Content: View>: View {
    let edge: DeckEdge
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        if edge.isVertical {
            VStack(alignment: edge == .right ? .trailing : .leading, spacing: spacing, content: content)
        } else {
            HStack(alignment: edge == .bottom ? .bottom : .top, spacing: spacing, content: content)
        }
    }
}
