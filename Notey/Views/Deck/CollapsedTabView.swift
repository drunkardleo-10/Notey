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
                if state == .expanded {
                    cardPreviewBody
                        .transition(.opacity.combined(with: .offset(x: -10)))
                }

                if state != .idle {
                    tabHandle
                }
            }
            .frame(
                width: state.size.width,
                height: state.size.height,
                alignment: .trailing
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
        }
        .frame(width: 34)
    }

    private var hasTasks: Bool {
        previewLines.contains(where: \.isTask)
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

            if hasTasks {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(previewLines.prefix(4).enumerated()), id: \.offset) { _, line in
                        HStack(spacing: 7) {
                            if line.isTask {
                                checkboxIcon(completed: line.isCompleted)
                            }
                            Text(line.text)
                                .font(NoteyFonts.note(size: 14))
                                .foregroundStyle(Color.textPrimary)
                                .strikethrough(line.isCompleted)
                                .opacity(line.isCompleted ? 0.55 : 1)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            } else {
                Text(note.body)
                    .font(NoteyFonts.note(size: 15))
                    .foregroundStyle(Color.textPrimary.opacity(0.9))
                    .lineSpacing(2.5)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
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
            RoundedRectangle(cornerRadius: 3.2)
                .stroke(Color.textPrimary, lineWidth: 1.6)
                .fill(completed ? Color.textPrimary : Color.clear)
                .frame(width: 14, height: 14)

            if completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.noteYellow)
            }
        }
    }

    private var previewLines: [PreviewLine] {
        guard !note.body.isEmpty else { return [] }
        let rawLines = note.body.components(separatedBy: "\n")
        var result: [PreviewLine] = []

        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let pattern = #"^[-*]\s*\[([ xX]?)\]\s*(.*)$"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
               let checkRange = Range(match.range(at: 1), in: trimmed),
               let textRange = Range(match.range(at: 2), in: trimmed) {
                result.append(PreviewLine(
                    isTask: true,
                    isCompleted: String(trimmed[checkRange]).lowercased() == "x",
                    text: String(trimmed[textRange]).trimmingCharacters(in: .whitespaces)
                ))
            } else {
                result.append(PreviewLine(
                    isTask: false,
                    isCompleted: false,
                    text: trimmed
                ))
            }
        }

        return result
    }
}

private struct PreviewLine {
    let isTask: Bool
    let isCompleted: Bool
    let text: String
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
        case .idle:     return 5
        case .peeking:  return 14
        case .expanded: return 18
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .idle:     return 0.20
        case .peeking:  return 0.16
        case .expanded: return 0.24
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .idle:     return 1.5
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
        case .idle:     return 0.5
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
