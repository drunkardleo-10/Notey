import SwiftUI

struct CollapsedTabView: View {
    let note: Note
    let edge: DeckEdge
    let isDeckHovered: Bool
    let isCardExpanded: Bool
    var onSelect: (() -> Void)?
    var onHover: (() -> Void)?
    var onLeave: (() -> Void)?

    private var tabLabel: String {
        let trimmed = note.title.trimmingCharacters(in: .whitespaces)
        let lower = trimmed.lowercased()
        if trimmed.isEmpty || lower == "untitled note" || lower == "untitled" || lower.hasPrefix("untitled") {
            return "NOTE"
        }
        let firstWord = trimmed.components(separatedBy: " ").first ?? "NOTE"
        let upper = firstWord.uppercased()
        if upper.count > 8 {
            return String(upper.prefix(7))
        }
        return upper
    }

    private var state: TabState {
        isCardExpanded ? .expanded : .peeking
    }

    private var tabSize: CGSize {
        edge.isVertical
            ? CGSize(width: state.depth, height: state.along)
            : CGSize(width: state.along, height: state.depth)
    }

    private var tabShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: edge.farCornerRadii(state.topLeadingRadius, state.bottomLeadingRadius)
        )
    }

    private func shadowOffset(_ depthAmount: CGFloat, _ alongAmount: CGFloat) -> CGSize {
        let away = -depthAmount.magnitude
        if edge.isVertical {
            return CGSize(width: away * edge.outward.width, height: alongAmount)
        }
        return CGSize(width: alongAmount, height: away * edge.outward.height)
    }

    var body: some View {
        let ambient = shadowOffset(state.shadowAmbientX, state.shadowAmbientY)
        let key = shadowOffset(state.shadowKeyX, state.shadowKeyY)

        Button(action: { onSelect?() }) {
            tabContent
                .frame(
                    width: tabSize.width,
                    height: tabSize.height,
                    alignment: edge.farAlignment
                )
                .background(note.color.swiftUIColor)
                .clipShape(tabShape)
                .shadow(
                    color: Color.black.opacity(state.shadowAmbientOpacity),
                    radius: state.shadowAmbientRadius,
                    x: ambient.width,
                    y: ambient.height
                )
                .shadow(
                    color: Color.black.opacity(state.shadowKeyOpacity),
                    radius: state.shadowKeyRadius,
                    x: key.width,
                    y: key.height
                )
                .contentShape(tabShape)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                onHover?()
            } else {
                onLeave?()
            }
        }
        .zIndex(state == .expanded ? 50 : 1)
        .animation(.noteySpring, value: state)
        .accessibilityLabel(note.title)
    }

    @ViewBuilder
    private var tabContent: some View {
        let reveal = AnyTransition.opacity.combined(
            with: .offset(x: edge.outward.width * 10, y: edge.outward.height * 10)
        )
        switch edge {
        case .right:
            HStack(spacing: 0) {
                tabHandle
                if state == .expanded { cardPreviewBody.transition(reveal) }
            }
        case .left:
            HStack(spacing: 0) {
                if state == .expanded { cardPreviewBody.transition(reveal) }
                tabHandle
            }
        case .bottom:
            VStack(spacing: 0) {
                tabHandle
                if state == .expanded { cardPreviewBody.transition(reveal) }
            }
        case .top:
            VStack(spacing: 0) {
                if state == .expanded { cardPreviewBody.transition(reveal) }
                tabHandle
            }
        }
    }

    private var dividerAlignment: Alignment {
        edge.alignment
    }

    private var tabHandle: some View {
        ZStack(alignment: dividerAlignment) {
            handleLabel

            Rectangle()
                .fill(Color.clear)
                .frame(
                    width: edge.isVertical ? 1.5 : nil,
                    height: edge.isVertical ? nil : 1.5
                )
                .overlay(
                    PerforationDivider(horizontal: !edge.isVertical)
                        .stroke(
                            Color.textPrimary.opacity(0.20),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4.5, 3.5])
                        )
                )
                .padding(edge == .right ? .trailing : edge == .left ? .leading : edge == .bottom ? .bottom : .top, 6)
        }
        .frame(
            width: edge.isVertical ? NoteyLayout.tabPeekingWidth : nil,
            height: edge.isVertical ? nil : NoteyLayout.tabPeekingWidth
        )
    }

    @ViewBuilder
    private var handleLabel: some View {
        if edge.isVertical {
            Text(tabLabel)
                .font(NoteyFonts.ui(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Color.textPrimary.opacity(0.72))
                .fixedSize()
                .lineLimit(1)
                .rotationEffect(.degrees(-90))
                .frame(width: 28, height: NoteyLayout.tabStepHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 4)
                .padding(.leading, edge == .left ? 6 : 2)
        } else {
            Text(tabLabel)
                .font(NoteyFonts.ui(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Color.textPrimary.opacity(0.72))
                .fixedSize()
                .lineLimit(1)
                .frame(height: 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 8)
                .padding(.top, edge == .top ? 6 : 2)
        }
    }

    private var cardPreviewBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.title.isEmpty ? "Untitled note" : note.title)
                .font(NoteyFonts.ui(size: 15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                ForEach(previewItems) { item in
                    HStack(spacing: 6) {
                        if item.isTask {
                            checkboxIcon(completed: item.isCompleted, text: item.text)
                        }
                        Text(item.attributedText)
                            .font(NoteyFonts.note(size: 15))
                            .foregroundStyle(Color.textPrimary)
                            .strikethrough(item.isCompleted)
                            .opacity(item.isCompleted ? 0.55 : 1)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.init(top: 14, leading: 12, bottom: 12, trailing: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func checkboxIcon(completed: Bool, text: String = "") -> some View {
        ScribbleCheckboxIcon(
            checked: completed,
            seed: ScribbleEngine.fnv1aHash(text),
            size: 14,
            strokeColor: Color.textPrimary.opacity(0.40),
            fillColor: Color.textPrimary.opacity(0.04),
            checkColor: Color.textPrimary
        )
    }


    private var previewItems: [PreviewItem] {
        guard !note.body.isEmpty else { return [] }
        let rawLines = note.body.components(separatedBy: "\n")
        var result: [PreviewItem] = []

        for (idx, rawLine) in rawLines.enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if result.count >= 5 { break }

            let taskPattern = #"^[-*]\s*\[([ xX]?)\]\s*(.*)$"#
            if let regex = try? NSRegularExpression(pattern: taskPattern),
               let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
               let checkRange = Range(match.range(at: 1), in: trimmed),
               let textRange = Range(match.range(at: 2), in: trimmed) {
                let isDone = String(trimmed[checkRange]).lowercased() == "x"
                let text = String(trimmed[textRange]).trimmingCharacters(in: .whitespaces)
                result.append(PreviewItem(
                    id: idx,
                    isTask: true,
                    isCompleted: isDone,
                    text: text,
                    attributedText: parseInlineMarkdown(text)
                ))
            } else if trimmed.hasPrefix("☐ ") || trimmed.hasPrefix("☑ ") {
                let isDone = trimmed.hasPrefix("☑ ")
                let text = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                result.append(PreviewItem(
                    id: idx,
                    isTask: true,
                    isCompleted: isDone,
                    text: text,
                    attributedText: parseInlineMarkdown(text)
                ))
            } else {
                result.append(PreviewItem(
                    id: idx,
                    isTask: false,
                    isCompleted: false,
                    text: trimmed,
                    attributedText: parseInlineMarkdown(trimmed)
                ))
            }
        }

        return result
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        if let attr = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attr
        }
        return AttributedString(text)
    }
}

private struct PreviewItem: Identifiable {
    let id: Int
    let isTask: Bool
    let isCompleted: Bool
    let text: String
    let attributedText: AttributedString
}

private enum TabState: Equatable {
    case peeking
    case expanded

    var depth: CGFloat {
        switch self {
        case .peeking:  return NoteyLayout.tabPeekingWidth
        case .expanded: return NoteyLayout.tabExpandedWidth
        }
    }

    var topWidth: CGFloat {
        switch self {
        case .peeking:  return NoteyLayout.tabPeekingWidth
        case .expanded: return NoteyLayout.tabExpandedWidth
        }
    }

    var bottomWidth: CGFloat {
        switch self {
        case .peeking:  return NoteyLayout.tabPeekingBottomWidth
        case .expanded: return NoteyLayout.tabExpandedWidth
        }
    }

    var along: CGFloat {
        switch self {
        case .peeking:  return NoteyLayout.tabPeekingHeight
        case .expanded: return NoteyLayout.tabExpandedHeight
        }
    }

    var topLeadingRadius: CGFloat {
        switch self {
        case .peeking:  return 16
        case .expanded: return 18
        }
    }

    var bottomLeadingRadius: CGFloat {
        switch self {
        case .peeking:  return 14
        case .expanded: return 18
        }
    }

    var shadowAmbientOpacity: Double {
        switch self {
        case .peeking:  return 0.16
        case .expanded: return 0.26
        }
    }

    var shadowAmbientRadius: CGFloat {
        switch self {
        case .peeking:  return 6
        case .expanded: return 18
        }
    }

    var shadowAmbientX: CGFloat {
        switch self {
        case .peeking:  return -2
        case .expanded: return -4
        }
    }

    var shadowAmbientY: CGFloat {
        switch self {
        case .peeking:  return 3
        case .expanded: return 6
        }
    }

    var shadowKeyOpacity: Double {
        switch self {
        case .peeking:  return 0.12
        case .expanded: return 0.20
        }
    }

    var shadowKeyRadius: CGFloat {
        switch self {
        case .peeking:  return 2
        case .expanded: return 5
        }
    }

    var shadowKeyX: CGFloat {
        switch self {
        case .peeking:  return -1
        case .expanded: return -2
        }
    }

    var shadowKeyY: CGFloat {
        switch self {
        case .peeking:  return 1
        case .expanded: return 3
        }
    }
}

struct TaperedTabShape: Shape {
    var topWidth: CGFloat
    var bottomWidth: CGFloat
    var topLeadingRadius: CGFloat
    var bottomLeadingRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(topWidth, bottomWidth),
                AnimatablePair(topLeadingRadius, bottomLeadingRadius)
            )
        }
        set {
            topWidth = newValue.first.first
            bottomWidth = newValue.first.second
            topLeadingRadius = newValue.second.first
            bottomLeadingRadius = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let rTop = max(0, min(topLeadingRadius, topWidth / 2, rect.height / 2))
        let rBottom = max(0, min(bottomLeadingRadius, bottomWidth / 2, rect.height / 2))
        let topX = rect.maxX - topWidth
        let bottomX = rect.maxX - bottomWidth

        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: topX + rTop, y: rect.minY))
        path.addArc(
            tangent1End: CGPoint(x: topX, y: rect.minY),
            tangent2End: CGPoint(x: bottomX, y: rect.maxY),
            radius: rTop
        )
        path.addArc(
            tangent1End: CGPoint(x: bottomX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.maxY),
            radius: rBottom
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PerforationDivider: Shape {
    var horizontal: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if horizontal {
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        return path
    }
}
