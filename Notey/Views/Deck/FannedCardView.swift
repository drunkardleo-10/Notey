import SwiftUI

struct FannedCardView: View {

    let note: Note
    let index: Int
    let total: Int
    var onSelect: ((Note) -> Void)?

    private var rotationAngle: Double {
        guard total > 1 else { return 0 }
        let step = 8.0 / Double(total - 1)
        return -4.0 + Double(index) * step
    }

    private var xOffset: CGFloat {
        CGFloat(abs(Double(index) - Double(total - 1) / 2.0)) * 6.0
    }

    private var tabLabel: String {
        let firstWord = note.title.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").first ?? "NOTE"
        return firstWord.uppercased()
    }

    private var formattedBody: AttributedString {
        let display = MarkdownBridge.toDisplay(note.body)
        if let attr = try? AttributedString(markdown: display, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attr
        }
        return AttributedString(display)
    }

    @State private var isHovered = false

    var body: some View {
        Button(action: { onSelect?(note) }) {
            HStack(spacing: 0) {
                
                ZStack(alignment: .trailing) {
                    Text(tabLabel)
                        .font(NoteyFonts.ui(size: 10, weight: .heavy))
                        .tracking(1.3)
                        .foregroundStyle(Color.textPrimary.opacity(0.65))
                        .rotationEffect(.degrees(180))
                        .fixedSize()
                        .lineLimit(1)
                        .frame(maxHeight: 140)
                        .environment(\.layoutDirection, .rightToLeft)

                    Rectangle()
                        .fill(Color.textPrimary.opacity(0.22))
                        .frame(width: 1.5)
                        .padding(.vertical, 6)
                }
                .frame(width: 36)

                VStack(alignment: .leading, spacing: 8) {
                    Text(note.title)
                        .font(NoteyFonts.ui(size: 15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(formattedBody)
                        .font(NoteyFonts.note(size: 14))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                }
                .padding(.init(top: 16, leading: 12, bottom: 16, trailing: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 320)
            .frame(minHeight: 180)
            .background(note.color.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: Color.textPrimary.opacity(isHovered ? 0.22 : 0.16),
                radius: isHovered ? 14 : 10,
                x: isHovered ? -4 : -2,
                y: isHovered ? 7 : 4
            )
            .rotationEffect(.degrees(isHovered ? 0 : rotationAngle))
            .offset(x: isHovered ? -12 : -xOffset)
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .zIndex(isHovered ? 60 : Double(10 + index))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel(note.title)
    }
}
