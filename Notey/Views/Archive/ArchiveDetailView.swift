import SwiftUI

struct ArchiveDetailView: View {

    let note: Note?
    var onRestore: ((UUID) -> Void)?
    var onDelete: ((UUID) -> Void)?

    var body: some View {
        if let note {
            VStack(alignment: .leading, spacing: 0) {
                
                HStack(spacing: 10) {
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(note.color.swiftUIColor)
                        .frame(width: 6, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title)
                            .font(NoteyFonts.ui(size: 18, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)

                        Text("Archived \(note.updatedAt.relativeString)")
                            .font(NoteyFonts.ui(size: 12))
                            .foregroundStyle(Color.textMuted)
                    }

                    Spacer()
                }
                .padding(.init(top: 18, leading: 18, bottom: 14, trailing: 18))

                Rectangle()
                    .fill(Color.textPrimary.opacity(0.08))
                    .frame(height: 1)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 5) {
                        let lines = note.body.components(separatedBy: "\n")
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            bodyLine(line)
                        }
                    }
                    .padding(.init(top: 14, leading: 18, bottom: 14, trailing: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)

                Rectangle()
                    .fill(Color.textPrimary.opacity(0.08))
                    .frame(height: 1)

                HStack {
                    
                    Button(action: { onDelete?(note.id) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .medium))
                            Text("Delete")
                                .font(NoteyFonts.ui(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.textDanger)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.textDanger.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { onRestore?(note.id) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .medium))
                            Text("Restore")
                                .font(NoteyFonts.ui(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.textPrimary)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.textPrimary.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.init(top: 12, leading: 18, bottom: 12, trailing: 18))
            }
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
        }
    }

    @ViewBuilder
    private func bodyLine(_ raw: String) -> some View {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            Spacer()
                .frame(height: 8)
        } else if let match = parseTask(trimmed) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.textPrimary, lineWidth: 1.4)
                        .fill(match.completed ? Color.textPrimary : Color.clear)
                        .frame(width: 14, height: 14)

                    if match.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }

                Text(match.text)
                    .font(NoteyFonts.note(size: 17))
                    .foregroundStyle(Color.textPrimary)
                    .strikethrough(match.completed)
                    .opacity(match.completed ? 0.55 : 1)
            }
        } else {
            Text(trimmed)
                .font(NoteyFonts.note(size: 17))
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
