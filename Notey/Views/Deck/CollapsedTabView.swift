import SwiftUI

struct CollapsedTabView: View {
    let note: Note
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
        return firstWord.uppercased()
    }

    private var state: TabState {
        if isCardExpanded { return .expanded }
        if isDeckHovered { return .peeking }
        return .idle
    }

    var body: some View {
        Button(action: { onSelect?() }) {
            HStack(spacing: 0) {
                tabHandle

                if state == .expanded {
                    cardPreviewBody
                        .transition(.opacity.combined(with: .offset(x: 10)))
                }
            }
            .frame(
                width: state.size.width,
                height: state.size.height,
                alignment: .leading
            )
            .background(note.color.swiftUIColor)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: state.cornerRadius,
                bottomLeadingRadius: state.cornerRadius,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            ))
            .shadow(
                color: Color.textPrimary.opacity(state.shadowOpacity),
                radius: state.shadowRadius,
                x: state.shadowX,
                y: state.shadowY
            )
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

    private var tabHandle: some View {
        ZStack(alignment: .trailing) {
            Text(tabLabel)
                .font(NoteyFonts.ui(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Color.textPrimary.opacity(0.75))
                .rotationEffect(.degrees(90))
                .fixedSize()
                .lineLimit(1)
                .frame(maxHeight: 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 14)
                .padding(.trailing, 6)
                .opacity(state == .idle ? 0 : 1)

            Rectangle()
                .fill(Color.clear)
                .frame(width: 1.5)
                .overlay(
                    PerforationDivider()
                        .stroke(
                            Color.textPrimary.opacity(0.22),
                            style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                        )
                )
                .padding(.trailing, 3)
                .opacity(state == .idle ? 0 : 1)
        }
        .frame(width: state == .idle ? NoteyLayout.tabIdleWidth : 34)
    }

    private var cardPreviewBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.title)
                    .font(NoteyFonts.ui(size: 15, weight: .heavy))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 4)

                Text(relativeDateString(for: note.updatedAt))
                    .font(NoteyFonts.ui(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textPrimary.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(previewItems) { item in
                    HStack(spacing: 7) {
                        if item.isTask {
                            checkboxIcon(completed: item.isCompleted)
                        } else if item.isBullet {
                            Text("•")
                                .font(NoteyFonts.note(size: 14))
                                .foregroundStyle(Color.textPrimary.opacity(0.75))
                        }
                        Text(item.attributedText)
                            .font(NoteyFonts.note(size: 14))
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
        .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 10))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func relativeDateString(for date: Date) -> String {
        let seconds = -date.timeIntervalSinceNow
        if seconds < 60 { return "now" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes)m" }
        let hours = Int(seconds / 3600)
        if hours < 24 { return "\(hours)h" }
        let days = Int(seconds / 86400)
        return "\(days)d"
    }

    private func checkboxIcon(completed: Bool) -> some View {
        ZStack {
            if completed {
                RoundedRectangle(cornerRadius: 4.5)
                    .fill(Color.textPrimary)
                    .frame(width: 17, height: 17)

                Image(systemName: "checkmark")
                    .font(.system(size: 9.5, weight: .black))
                    .foregroundStyle(note.color.swiftUIColor)
            } else {
                RoundedRectangle(cornerRadius: 4.5)
                    .stroke(Color.textPrimary.opacity(0.42), lineWidth: 1.8)
                    .background(
                        RoundedRectangle(cornerRadius: 4.5)
                            .fill(Color.textPrimary.opacity(0.06))
                    )
                    .frame(width: 17, height: 17)
            }
        }
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
                    isBullet: false,
                    attributedText: parseInlineMarkdown(text)
                ))
            } else if trimmed.hasPrefix("☐ ") || trimmed.hasPrefix("☑ ") {
                let isDone = trimmed.hasPrefix("☑ ")
                let text = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                result.append(PreviewItem(
                    id: idx,
                    isTask: true,
                    isCompleted: isDone,
                    isBullet: false,
                    attributedText: parseInlineMarkdown(text)
                ))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                let text = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                result.append(PreviewItem(
                    id: idx,
                    isTask: false,
                    isCompleted: false,
                    isBullet: true,
                    attributedText: parseInlineMarkdown(text)
                ))
            } else {
                result.append(PreviewItem(
                    id: idx,
                    isTask: false,
                    isCompleted: false,
                    isBullet: false,
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
    let isBullet: Bool
    let attributedText: AttributedString
}

private enum TabState: Equatable {
    case idle
    case peeking
    case expanded

    var size: CGSize {
        switch self {
        case .idle:     return CGSize(width: NoteyLayout.tabIdleWidth, height: NoteyLayout.tabIdleHeight)
        case .peeking:  return CGSize(width: NoteyLayout.tabPeekingWidth, height: NoteyLayout.tabPeekingHeight)
        case .expanded: return CGSize(width: NoteyLayout.tabExpandedWidth, height: NoteyLayout.tabExpandedHeight)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .idle:     return 4
        case .peeking:  return 14
        case .expanded: return 18
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .idle:     return 0.16
        case .peeking:  return 0.16
        case .expanded: return 0.24
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .idle:     return 4
        case .peeking:  return 4
        case .expanded: return 12
        }
    }

    var shadowX: CGFloat {
        switch self {
        case .idle:     return -1
        case .peeking:  return -1
        case .expanded: return -2.5
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .idle:     return 1.5
        case .peeking:  return 1.5
        case .expanded: return 4
        }
    }
}

private struct PerforationDivider: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
