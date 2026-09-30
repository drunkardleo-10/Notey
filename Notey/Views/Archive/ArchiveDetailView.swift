import SwiftUI

struct ArchiveDetailView: View {

    let note: Note?
    var onRestore: ((UUID) -> Void)?
    var onDelete: ((UUID) -> Void)?

    var body: some View {
        if let note {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(note.color.swiftUIColor)
                            .frame(width: 10, height: 10)

                        Text(note.updatedAt.archivedHeaderString)
                            .font(NoteyFonts.ui(size: 11, weight: .bold))
                            .foregroundStyle(Color.textPrimary.opacity(0.55))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: { onRestore?(note.id) }) {
                            Text("Restore to deck")
                                .font(NoteyFonts.ui(size: 12, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.textPrimary.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: { onDelete?(note.id) }) {
                            Text("Delete")
                                .font(NoteyFonts.ui(size: 12, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.textPrimary.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(note.title.isEmpty ? "Untitled note" : note.title)
                            .font(NoteyFonts.ui(size: 17, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(note.updatedAt.editedString)
                            .font(NoteyFonts.ui(size: 11))
                            .foregroundStyle(Color.textPrimary.opacity(0.6))
                    }

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 4) {
                            let lines = note.body.components(separatedBy: "\n")
                            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                                bodyLine(line)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(note.color.swiftUIColor)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.cream)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "archivebox")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(Color.textMuted.opacity(0.4))

                Text("Select a note")
                    .font(NoteyFonts.ui(size: 15))
                    .foregroundStyle(Color.textMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cream)
        }
    }

    @ViewBuilder
    private func bodyLine(_ raw: String) -> some View {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            Spacer().frame(height: 8)
        } else if let match = parseTask(trimmed) {
            HStack(spacing: 8) {
                ScribbleCheckboxIcon(
                    checked: match.completed,
                    seed: ScribbleEngine.fnv1aHash(match.text),
                    size: 14,
                    strokeColor: Color.textPrimary.opacity(0.40),
                    fillColor: Color.textPrimary.opacity(0.04),
                    checkColor: Color.textPrimary
                )


                Text(match.text)
                    .font(NoteyFonts.note(size: 18))
                    .foregroundStyle(Color.textPrimary)
                    .strikethrough(match.completed)
                    .opacity(match.completed ? 0.55 : 1)
            }
        } else {
            Text(trimmed)
                .font(NoteyFonts.note(size: 18))
                .foregroundStyle(Color.textPrimary)
        }
    }

    private struct TaskMatch {
        let completed: Bool
        let text: String
    }

    private func parseTask(_ line: String) -> TaskMatch? {
        let pattern = #"^[-*]\s+\[([ xX])\]\s*(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let checkRange = Range(match.range(at: 1), in: line),
              let textRange = Range(match.range(at: 2), in: line) else {
            return nil
        }
        return TaskMatch(
            completed: String(line[checkRange]).lowercased() == "x",
            text: String(line[textRange])
        )
    }
}
