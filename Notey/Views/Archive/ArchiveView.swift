import SwiftUI

struct ArchiveView: View {

    let noteStore: NoteStore
    var onClose: (() -> Void)?

    @State private var selectedNoteId: UUID? = nil
    @State private var searchQuery: String = ""

    private var selectedNote: Note? {
        guard let id = selectedNoteId else { return nil }
        return noteStore.archivedNotes.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 8) {
                
                Button(action: { onClose?() }) {
                    Circle()
                        .fill(Color(hex: 0xFF5F56))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close archive")

                Spacer()

                Text("Archive")
                    .font(NoteyFonts.ui(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Color.clear.frame(width: 12, height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.cream)

            Rectangle()
                .fill(Color.textPrimary.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 0) {
                
                ArchiveListView(
                    archivedNotes: noteStore.archivedNotes,
                    selectedNoteId: $selectedNoteId,
                    searchQuery: $searchQuery
                )
                .frame(width: 240)

                Rectangle()
                    .fill(Color.textPrimary.opacity(0.08))
                    .frame(width: 1)

                ArchiveDetailView(
                    note: selectedNote,
                    onRestore: { id in
                        noteStore.restoreNote(id: id)
                        selectedNoteId = nil
                    },
                    onDelete: { id in
                        noteStore.deleteNote(id: id)
                        selectedNoteId = nil
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(
            width: NoteyLayout.archiveWidth,
            height: NoteyLayout.archiveHeight
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cream)
                .shadow(
                    color: Color.textPrimary.opacity(0.2),
                    radius: 24,
                    x: 0,
                    y: 8
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onExitCommand { onClose?() }
    }
}
