import SwiftUI

struct ArchiveListView: View {

    let archivedNotes: [Note]
    @Binding var selectedNoteId: UUID?
    @Binding var searchQuery: String
    var onClose: (() -> Void)?

    private var filteredNotes: [Note] {
        guard !searchQuery.isEmpty else { return archivedNotes }
        let q = searchQuery.lowercased()
        return archivedNotes.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Button(action: { onClose?() }) {
                    Circle()
                        .fill(Color(hex: 0xFF5F56))
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close archive")

                Circle()
                    .fill(Color(hex: 0xFFBD2E))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))

                Circle()
                    .fill(Color(hex: 0x27C93F))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))

                Spacer()
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            HStack {
                Text("Archive")
                    .font(NoteyFonts.ui(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textMuted)

                TextField("Search archived notes", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(NoteyFonts.ui(size: 12))
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 4)

                Text("\(filteredNotes.count) \(filteredNotes.count == 1 ? "note" : "notes")")
                    .font(NoteyFonts.ui(size: 11))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6.5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.textPrimary.opacity(0.06))
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    if filteredNotes.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 26, weight: .light))
                                .foregroundStyle(Color.textMuted.opacity(0.5))
                            Text(searchQuery.isEmpty ? "No archived notes" : "No results")
                                .font(NoteyFonts.ui(size: 13))
                                .foregroundStyle(Color.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                    } else {
                        ForEach(filteredNotes) { note in
                            ArchiveNoteRow(
                                note: note,
                                isSelected: selectedNoteId == note.id,
                                onSelect: { selectedNoteId = note.id }
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(Color.cream)
    }
}

private struct ArchiveNoteRow: View {

    let note: Note
    let isSelected: Bool
    var onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(note.color.swiftUIColor)
                    .frame(width: 3.5, height: 26)

                VStack(alignment: .leading, spacing: 1.5) {
                    Text(note.title.isEmpty ? "Untitled note" : note.title)
                        .font(NoteyFonts.ui(size: 13, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Text(previewText)
                        .font(NoteyFonts.note(size: 14))
                        .foregroundStyle(Color.textPrimary.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Text(note.updatedAt.shortRelativeString)
                    .font(NoteyFonts.ui(size: 11))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6.5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? Color.textPrimary.opacity(0.12)
                            : (isHovered ? Color.textPrimary.opacity(0.05) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var previewText: String {
        if note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Empty note"
        }
        return MarkdownBridge.toDisplay(note.body)
            .replacingOccurrences(of: "\n", with: " ")
    }
}

extension Date {
    var shortRelativeString: String {
        let now = Date()
        let interval = max(0, now.timeIntervalSince(self))
        if interval < 60 {
            return "\(max(1, Int(interval)))s"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else if interval < 604800 {
            return "\(Int(interval / 86400))d"
        } else if interval < 2592000 {
            return "\(Int(interval / 604800))w"
        } else if interval < 31536000 {
            return "\(Int(interval / 2592000))mo"
        } else {
            return "\(Int(interval / 31536000))y"
        }
    }

    var archivedHeaderString: String {
        let now = Date()
        let interval = max(0, now.timeIntervalSince(self))
        let timeStr: String
        if interval < 60 {
            timeStr = "\(max(1, Int(interval)))S AGO"
        } else if interval < 3600 {
            timeStr = "\(Int(interval / 60))M AGO"
        } else if interval < 86400 {
            timeStr = "\(Int(interval / 3600))H AGO"
        } else if interval < 604800 {
            timeStr = "\(Int(interval / 86400))D AGO"
        } else if interval < 2592000 {
            timeStr = "\(Int(interval / 604800))W AGO"
        } else {
            timeStr = "\(Int(interval / 2592000))MO AGO"
        }
        return "ARCHIVED \(timeStr)"
    }

    var editedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return "edited \(formatter.string(from: self))"
    }

    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
