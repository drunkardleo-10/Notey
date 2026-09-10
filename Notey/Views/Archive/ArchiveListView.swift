import SwiftUI

struct ArchiveListView: View {

    let archivedNotes: [Note]
    @Binding var selectedNoteId: UUID?
    @Binding var searchQuery: String

    private var filteredNotes: [Note] {
        guard !searchQuery.isEmpty else { return archivedNotes }
        let q = searchQuery.lowercased()
        return archivedNotes.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textMuted)

                TextField("Search archive…", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(NoteyFonts.ui(size: 14))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.textPrimary.opacity(0.04))

            Rectangle()
                .fill(Color.textPrimary.opacity(0.08))
                .frame(height: 1)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    if filteredNotes.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(Color.textMuted.opacity(0.5))
                            Text(searchQuery.isEmpty ? "No archived notes" : "No results")
                                .font(NoteyFonts.ui(size: 14))
                                .foregroundStyle(Color.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
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
            }
        }
    }
}

private struct ArchiveNoteRow: View {

    let note: Note
    let isSelected: Bool
    var onSelect: (() -> Void)?

    var body: some View {
        Button(action: { onSelect?() }) {
            HStack(spacing: 10) {
                
                Circle()
                    .fill(note.color.swiftUIColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(NoteyFonts.ui(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Text(note.body.isEmpty ? "Empty note" : note.body.replacingOccurrences(of: "\n", with: " "))
                        .font(NoteyFonts.ui(size: 11))
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(note.updatedAt.relativeString)
                    .font(NoteyFonts.ui(size: 10))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? Color.textPrimary.opacity(0.08)
                    : Color.clear
            )
        }
        .buttonStyle(.plain)

        Rectangle()
            .fill(Color.textPrimary.opacity(0.05))
            .frame(height: 1)
    }
}

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
